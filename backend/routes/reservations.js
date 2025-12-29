
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Reservation = require('../models/Reservation');
const Notification = require('../models/Notification');
const User = require('../models/User');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);


// @route   GET /api/reservations
// @desc    Obtenir toutes les réservations de l'utilisateur
// @access  Private
router.get('/', protect, async (req, res) => {
    try {
        const { upcoming, status } = req.query;

        const query = { userId: req.user.id };

        if (upcoming === 'true') {
            query.status = { $in: ['pending', 'assigned', 'inProgress'] };
            query.departureTime = { $gte: new Date() };
        }

        if (status) {
            query.status = status;
        }

        const reservations = await Reservation.find(query)
            .populate('vehicle')
            .populate('parkingSpot')
            .populate('workerId', 'firstName lastName phoneNumber')
            .sort({ departureTime: -1 });

        res.status(200).json({
            success: true,
            count: reservations.length,
            reservations,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des réservations:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des réservations',
        });
    }
});

// @route   GET /api/reservations/:id
// @desc    Obtenir une réservation par ID
// @access  Private
router.get('/:id', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOne({
            _id: req.params.id,
            userId: req.user.id,
        })
            .populate('vehicle')
            .populate('parkingSpot')
            .populate('workerId', 'firstName lastName phoneNumber');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        res.status(200).json({
            success: true,
            reservation,
        });
    } catch (error) {
        console.error('Erreur lors de la récupération de la réservation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération de la réservation',
        });
    }
});

// @route   POST /api/reservations
// @desc    Créer une nouvelle réservation
// @access  Private
router.post('/', protect, async (req, res) => {
    try {
        const {
            vehicleId,
            parkingSpotId,
            parkingSpotNumber, // ✅ Ajouté ici
            customLocation,
            departureTime,
            deadlineTime,
            serviceOptions,
            snowDepthCm,
            totalPrice,
            paymentMethod,
            // Localisation GPS pour le système déneigeur
            latitude,
            longitude,
            address,
        } = req.body;

        console.log('📝 Nouvelle réservation:', {
            userId: req.user.id,
            vehicleId,
            parkingSpotId,
            parkingSpotNumber,
            customLocation,
            departureTime,
            totalPrice,
        });

        // ✅ Gérer les différents cas de place de parking
        let finalParkingSpotId = null;
        let finalParkingSpotNumber = null;
        let finalCustomLocation = null;

        if (parkingSpotId && parkingSpotId.startsWith('manual-')) {
            // Place manuelle avec numéro
            finalParkingSpotNumber = parkingSpotId.replace('manual-', '');
            console.log('✅ Place manuelle:', finalParkingSpotNumber);
        } else if (parkingSpotId && parkingSpotId.startsWith('custom-')) {
            // Emplacement personnalisé
            finalCustomLocation = parkingSpotId.replace('custom-', '');
            console.log('✅ Emplacement personnalisé:', finalCustomLocation);
        } else if (parkingSpotId) {
            // ID de place valide
            finalParkingSpotId = parkingSpotId;
            console.log('✅ Place de parking ID:', finalParkingSpotId);
        } else if (parkingSpotNumber) {
            // Numéro fourni directement
            finalParkingSpotNumber = parkingSpotNumber;
            console.log('✅ Numéro de place fourni:', parkingSpotNumber);
        } else if (customLocation) {
            // Emplacement fourni directement
            finalCustomLocation = customLocation;
            console.log('✅ Emplacement fourni:', customLocation);
        }

        // Vérifier que les coordonnées GPS sont fournies (OBLIGATOIRE)
        if (!latitude || !longitude) {
            return res.status(400).json({
                success: false,
                message: 'La localisation GPS est requise pour créer une réservation',
                code: 'LOCATION_REQUIRED',
            });
        }

        // Construire l'objet location GeoJSON
        const locationData = {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)], // GeoJSON: [lng, lat]
            address: address || finalCustomLocation || 'Adresse non spécifiée',
        };

        const reservation = await Reservation.create({
            userId: req.user.id,
            vehicle: vehicleId,
            parkingSpot: finalParkingSpotId,
            parkingSpotNumber: finalParkingSpotNumber,
            customLocation: finalCustomLocation,
            departureTime: new Date(departureTime),
            deadlineTime: new Date(deadlineTime),
            serviceOptions: serviceOptions || [],
            snowDepthCm,
            basePrice: totalPrice,
            totalPrice,
            paymentMethod,
            // Localisation GPS (obligatoire)
            location: locationData,
        });

        // ✅ IMPORTANT: Populer les relations avant de renvoyer
        await reservation.populate('vehicle');
        if (finalParkingSpotId) {
            await reservation.populate('parkingSpot');
        }

        console.log('✅ Réservation créée avec succès:', reservation._id);

        // ✅ Créer l'ID de parking avec le numéro/emplacement pour l'édition future
        const manualSpotId = finalCustomLocation
            ? `custom-${finalCustomLocation}`
            : finalParkingSpotNumber
                ? `manual-${finalParkingSpotNumber}`
                : 'manual';

        res.status(201).json({
            success: true,
            reservation: {
                id: reservation._id.toString(),
                userId: reservation.userId.toString(),
                workerId: reservation.workerId?.toString(),
                vehicle: reservation.vehicle, // ✅ Déjà populé
                parkingSpot: reservation.parkingSpot || {
                    // ✅ Créer un objet factice si place manuelle (avec ID complet)
                    id: manualSpotId,
                    spotNumber: finalParkingSpotNumber || finalCustomLocation || 'N/A',
                    level: 'outdoor',
                    displayName: finalParkingSpotNumber || finalCustomLocation || 'N/A',
                    fullDisplayName: finalParkingSpotNumber || finalCustomLocation || 'N/A',
                    isAssigned: false,
                    isActive: true,
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString(),
                },
                departureTime: reservation.departureTime.toISOString(),
                deadlineTime: reservation.deadlineTime?.toISOString(),
                status: reservation.status,
                serviceOptions: reservation.serviceOptions,
                basePrice: reservation.basePrice,
                totalPrice: reservation.totalPrice,
                isPriority: reservation.isPriority,
                snowDepthCm: reservation.snowDepthCm,
                paymentMethod: reservation.paymentMethod,
                paymentStatus: reservation.paymentStatus,
                createdAt: reservation.createdAt.toISOString(),
            },
            message: 'Réservation créée avec succès',
        });
    } catch (error) {
        console.error('❌ Erreur lors de la création de la réservation:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Erreur lors de la création de la réservation',
        });
    }
});

// @route   PUT /api/reservations/:id
// @desc    Mettre à jour une réservation
// @access  Private
router.put('/:id', protect, async (req, res) => {
    try {
        // Mapper les champs du frontend vers le schéma backend
        const updateData = { ...req.body };

        // Mapper vehicleId vers vehicle
        if (updateData.vehicleId) {
            updateData.vehicle = updateData.vehicleId;
            delete updateData.vehicleId;
        }

        // ✅ Gérer les différents cas de place de parking (comme dans POST)
        if (updateData.parkingSpotId) {
            const parkingSpotId = updateData.parkingSpotId;
            delete updateData.parkingSpotId;

            if (parkingSpotId === 'manual' || parkingSpotId.startsWith('manual-')) {
                // Place manuelle avec numéro
                updateData.parkingSpot = null; // Pas de référence ObjectId
                updateData.parkingSpotNumber = parkingSpotId === 'manual'
                    ? updateData.parkingSpotNumber
                    : parkingSpotId.replace('manual-', '');
                updateData.customLocation = null;
                console.log('✅ Mise à jour avec place manuelle:', updateData.parkingSpotNumber);
            } else if (parkingSpotId.startsWith('custom-')) {
                // Emplacement personnalisé
                updateData.parkingSpot = null;
                updateData.parkingSpotNumber = null;
                updateData.customLocation = parkingSpotId.replace('custom-', '');
                console.log('✅ Mise à jour avec emplacement perso:', updateData.customLocation);
            } else if (parkingSpotId && parkingSpotId.length === 24) {
                // ID de place valide (ObjectId MongoDB = 24 caractères hex)
                updateData.parkingSpot = parkingSpotId;
                updateData.parkingSpotNumber = null;
                updateData.customLocation = null;
                console.log('✅ Mise à jour avec place ID:', parkingSpotId);
            }
        }

        // ✅ Gérer la mise à jour de la localisation GPS
        if (updateData.latitude && updateData.longitude) {
            updateData.location = {
                type: 'Point',
                coordinates: [parseFloat(updateData.longitude), parseFloat(updateData.latitude)],
                address: updateData.address || 'Adresse mise à jour',
            };
            console.log('✅ Mise à jour localisation GPS:', updateData.location);
            // Nettoyer les champs temporaires
            delete updateData.latitude;
            delete updateData.longitude;
            delete updateData.address;
        }

        const reservation = await Reservation.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            updateData,
            { new: true, runValidators: true }
        )
            .populate('vehicle')
            .populate('parkingSpot')
            .populate('workerId');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // ✅ Formater la réponse avec parkingSpot factice si place manuelle
        const responseReservation = reservation.toObject();
        if (!responseReservation.parkingSpot && (responseReservation.parkingSpotNumber || responseReservation.customLocation)) {
            const spotNumber = responseReservation.parkingSpotNumber || responseReservation.customLocation || 'N/A';
            const spotId = responseReservation.customLocation
                ? `custom-${spotNumber}`
                : `manual-${spotNumber}`;
            responseReservation.parkingSpot = {
                id: spotId,
                spotNumber: spotNumber,
                level: 'outdoor',
                displayName: spotNumber,
                fullDisplayName: spotNumber,
                isAssigned: false,
                isActive: true,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString(),
            };
        }

        res.status(200).json({
            success: true,
            reservation: responseReservation,
            message: 'Réservation mise à jour avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de la réservation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la mise à jour de la réservation',
        });
    }
});

// @route   DELETE /api/reservations/:id
// @desc    Annuler une réservation
// @access  Private
router.delete('/:id', protect, async (req, res) => {
    try {
        const { reason } = req.body;

        const reservation = await Reservation.findOneAndUpdate(
            {
                _id: req.params.id,
                userId: req.user.id,
                status: { $in: ['pending', 'assigned'] },
            },
            {
                status: 'cancelled',
                cancelledAt: new Date(),
                cancelReason: reason || 'Annulée par l\'utilisateur',
            },
            { new: true }
        );

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou ne peut pas être annulée',
            });
        }

        // Envoyer notification d'annulation
        await Notification.notifyReservationCancelled(
            reservation,
            reason || 'Annulée par l\'utilisateur'
        );

        res.status(200).json({
            success: true,
            reservation,
            message: 'Réservation annulée avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de l\'annulation de la réservation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'annulation de la réservation',
        });
    }
});

// @route   PATCH /api/reservations/:id/assign
// @desc    Assigner un déneigeur à une réservation
// @access  Private (Worker)
router.patch('/:id/assign', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findByIdAndUpdate(
            req.params.id,
            {
                workerId: req.user.id,
                status: 'assigned',
            },
            { new: true }
        ).populate('userId', 'firstName lastName');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Envoyer notification au client
        await Notification.notifyReservationAssigned(reservation, req.user);

        res.status(200).json({
            success: true,
            reservation,
            message: 'Réservation assignée avec succès',
        });
    } catch (error) {
        console.error('Erreur lors de l\'assignation:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'assignation',
        });
    }
});

// @route   PATCH /api/reservations/:id/en-route
// @desc    Indiquer que le déneigeur est en route
// @access  Private (Worker)
router.patch('/:id/en-route', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOne({
            _id: req.params.id,
            workerId: req.user.id,
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Envoyer notification au client
        await Notification.notifyWorkerEnRoute(reservation, req.user);

        res.status(200).json({
            success: true,
            message: 'Notification envoyée',
        });
    } catch (error) {
        console.error('Erreur:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi de la notification',
        });
    }
});

// @route   PATCH /api/reservations/:id/start
// @desc    Démarrer le travail
// @access  Private (Worker)
router.patch('/:id/start', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOneAndUpdate(
            {
                _id: req.params.id,
                workerId: req.user.id,
            },
            {
                status: 'inProgress',
            },
            { new: true }
        );

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée',
            });
        }

        // Envoyer notification au client
        await Notification.notifyWorkStarted(reservation, req.user);

        res.status(200).json({
            success: true,
            reservation,
            message: 'Travail démarré',
        });
    } catch (error) {
        console.error('Erreur:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors du démarrage',
        });
    }
});

// Configuration des commissions
const PLATFORM_FEE_PERCENT = 0.25; // 25% pour la plateforme

// @route   PATCH /api/reservations/:id/complete
// @desc    Marquer le travail comme terminé et payer le déneigeur
// @access  Private (Worker)
router.patch('/:id/complete', protect, async (req, res) => {
    try {
        const reservation = await Reservation.findOne({
            _id: req.params.id,
            workerId: req.user.id,
            status: 'inProgress',
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou pas en cours',
            });
        }

        // Récupérer le worker pour son compte Stripe Connect
        const worker = await User.findById(req.user.id);

        // Calculer les montants
        const totalAmount = reservation.totalPrice;
        const tipAmount = reservation.tipAmount || 0;
        const platformFee = totalAmount * PLATFORM_FEE_PERCENT;
        const workerAmount = totalAmount - platformFee + tipAmount; // Worker reçoit 75% + pourboire

        // Mettre à jour la réservation
        reservation.status = 'completed';
        reservation.completedAt = new Date();
        reservation.payout = {
            status: 'pending',
            workerAmount: workerAmount,
            platformFee: platformFee,
            tipAmount: tipAmount,
            processedAt: null,
        };

        // Transférer l'argent au déneigeur via Stripe Connect
        let transferResult = null;
        if (worker.workerProfile?.stripeConnectId && reservation.paymentStatus === 'paid') {
            try {
                const transfer = await stripe.transfers.create({
                    amount: Math.round(workerAmount * 100), // En cents
                    currency: 'cad',
                    destination: worker.workerProfile.stripeConnectId,
                    description: `Paiement job #${reservation._id}`,
                    metadata: {
                        reservationId: reservation._id.toString(),
                        workerId: worker._id.toString(),
                        originalAmount: totalAmount,
                        platformFee: platformFee,
                        tipAmount: tipAmount,
                    },
                });

                reservation.payout.status = 'completed';
                reservation.payout.stripeTransferId = transfer.id;
                reservation.payout.processedAt = new Date();

                transferResult = {
                    success: true,
                    transferId: transfer.id,
                    amount: workerAmount,
                };

                console.log(`✅ Transfert Stripe créé: ${transfer.id} - ${workerAmount}$`);

                // Mettre à jour les stats du worker
                worker.workerProfile.totalJobsCompleted = (worker.workerProfile.totalJobsCompleted || 0) + 1;
                worker.workerProfile.totalEarnings = (worker.workerProfile.totalEarnings || 0) + workerAmount;
                worker.workerProfile.totalTipsReceived = (worker.workerProfile.totalTipsReceived || 0) + tipAmount;
                await worker.save();

            } catch (stripeError) {
                console.error('❌ Erreur transfert Stripe:', stripeError.message);
                reservation.payout.status = 'failed';
                reservation.payout.error = stripeError.message;

                transferResult = {
                    success: false,
                    error: stripeError.message,
                };
            }
        } else if (!worker.workerProfile?.stripeConnectId) {
            reservation.payout.status = 'pending_account';
            reservation.payout.note = 'En attente de configuration du compte de paiement';

            transferResult = {
                success: false,
                error: 'Compte Stripe Connect non configuré',
                needsSetup: true,
            };
        } else {
            reservation.payout.status = 'pending_payment';
            reservation.payout.note = 'En attente du paiement client';
        }

        await reservation.save();

        // Envoyer notification au client
        await Notification.notifyWorkCompleted(reservation, req.user);

        // Notifier le worker de son paiement
        await Notification.create({
            userId: worker._id,
            type: 'paymentSuccess',
            title: 'Paiement reçu',
            message: transferResult?.success
                ? `Vous avez reçu ${workerAmount.toFixed(2)}$ pour le job terminé${tipAmount > 0 ? ` (incluant ${tipAmount.toFixed(2)}$ de pourboire)` : ''}.`
                : `Job terminé! ${!worker.workerProfile?.stripeConnectId ? 'Configurez votre compte de paiement pour recevoir vos gains.' : 'Paiement en attente.'}`,
            priority: 'high',
            reservationId: reservation._id,
            metadata: {
                workerAmount,
                platformFee,
                tipAmount,
                transferStatus: reservation.payout.status,
            },
        });

        res.status(200).json({
            success: true,
            reservation,
            message: 'Travail terminé avec succès',
            payout: {
                workerAmount,
                platformFee,
                tipAmount,
                status: reservation.payout.status,
                transfer: transferResult,
            },
        });
    } catch (error) {
        console.error('Erreur:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la complétion',
        });
    }
});

// @route   POST /api/payments/create-intent
// @desc    Créer un Payment Intent Stripe
// @access  Private
router.post('/create-intent', protect, async (req, res) => {
    try {
        const { amount } = req.body; // Montant en dollars

        const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(amount * 100), // Stripe utilise les cents
            currency: 'cad',
            metadata: {
                userId: req.user.id,
            },
        });

        res.status(200).json({
            success: true,
            clientSecret: paymentIntent.client_secret,
            paymentIntentId: paymentIntent.id,
        });
    } catch (error) {
        console.error('Erreur Stripe:', error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
});

// ============================================================================
// LOGIQUE MÉTIER D'ANNULATION
// ============================================================================

// Constantes pour la politique d'annulation
const CANCELLATION_POLICY = {
    // Seuils d'avertissement pour les déneigeurs
    WARNING_THRESHOLD: 2,        // Nombre d'annulations avant avertissement
    SUSPENSION_THRESHOLD: 5,     // Nombre d'annulations avant suspension
    SUSPENSION_DAYS: 7,          // Durée de suspension en jours

    // Pénalités pour les clients
    EN_ROUTE_FEE_PERCENT: 50,    // 50% si déneigeur en route
    IN_PROGRESS_FEE_PERCENT: 100, // 100% si travail commencé
};

// Raisons valables d'annulation pour les déneigeurs
const VALID_WORKER_CANCELLATION_REASONS = [
    'vehicle_breakdown',      // Panne de véhicule
    'medical_emergency',      // Urgence médicale
    'severe_weather',         // Conditions météo dangereuses
    'road_blocked',           // Route bloquée/inaccessible
    'family_emergency',       // Urgence familiale
    'equipment_failure',      // Équipement défaillant
    'other',                  // Autre (nécessite description)
];

/**
 * @route   PATCH /api/reservations/:id/cancel-by-worker
 * @desc    Annulation par le déneigeur - avec suivi et conséquences
 * @access  Private (Worker)
 */
router.patch('/:id/cancel-by-worker', protect, async (req, res) => {
    try {
        const { reason, reasonCode, description } = req.body;

        // Vérifier que l'utilisateur est un déneigeur
        if (req.user.role !== 'snowWorker') {
            return res.status(403).json({
                success: false,
                message: 'Seuls les déneigeurs peuvent utiliser cette fonctionnalité',
            });
        }

        // Vérifier si le déneigeur est suspendu
        const worker = await User.findById(req.user.id);
        if (worker.workerProfile?.isSuspended) {
            const suspendedUntil = worker.workerProfile.suspendedUntil;
            if (suspendedUntil && new Date() < suspendedUntil) {
                return res.status(403).json({
                    success: false,
                    message: `Votre compte est suspendu jusqu'au ${suspendedUntil.toLocaleDateString('fr-CA')}`,
                    suspendedUntil,
                });
            }
            // Lever la suspension si elle est expirée
            worker.workerProfile.isSuspended = false;
            worker.workerProfile.suspendedUntil = null;
            worker.workerProfile.suspensionReason = null;
            await worker.save();
        }

        // Valider la raison
        if (!reasonCode || !VALID_WORKER_CANCELLATION_REASONS.includes(reasonCode)) {
            return res.status(400).json({
                success: false,
                message: 'Une raison valable est requise pour annuler',
                validReasons: VALID_WORKER_CANCELLATION_REASONS,
            });
        }

        if (reasonCode === 'other' && (!description || description.length < 10)) {
            return res.status(400).json({
                success: false,
                message: 'Veuillez fournir une description détaillée (minimum 10 caractères)',
            });
        }

        // Trouver la réservation assignée à ce déneigeur
        const reservation = await Reservation.findOne({
            _id: req.params.id,
            workerId: req.user.id,
            status: { $in: ['assigned', 'enRoute', 'inProgress'] },
        });

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou vous n\'êtes pas assigné à cette tâche',
            });
        }

        const fullReason = reasonCode === 'other'
            ? `${reason || 'Autre raison'}: ${description}`
            : reason || reasonCode;

        // Mettre à jour la réservation
        reservation.status = 'cancelled';
        reservation.cancelledAt = new Date();
        reservation.cancelledBy = 'worker';
        reservation.cancelReason = fullReason;
        reservation.workerId = null; // Libérer la réservation pour un autre déneigeur

        // Réinitialiser pour permettre une nouvelle assignation
        reservation.assignedAt = null;
        reservation.workerEnRouteAt = null;
        reservation.startedAt = null;

        await reservation.save();

        // Mettre à jour le profil du déneigeur
        worker.workerProfile.totalCancellations = (worker.workerProfile.totalCancellations || 0) + 1;
        worker.workerProfile.cancellationHistory = worker.workerProfile.cancellationHistory || [];
        worker.workerProfile.cancellationHistory.push({
            reservationId: reservation._id,
            reason: fullReason,
            cancelledAt: new Date(),
        });

        // Calculer les conséquences
        let consequence = null;
        const totalCancellations = worker.workerProfile.totalCancellations;

        if (totalCancellations >= CANCELLATION_POLICY.SUSPENSION_THRESHOLD) {
            // Suspension
            const suspendedUntil = new Date();
            suspendedUntil.setDate(suspendedUntil.getDate() + CANCELLATION_POLICY.SUSPENSION_DAYS);

            worker.workerProfile.isSuspended = true;
            worker.workerProfile.suspendedUntil = suspendedUntil;
            worker.workerProfile.suspensionReason = `Trop d'annulations (${totalCancellations})`;
            worker.workerProfile.warningCount = 0; // Reset après suspension

            consequence = {
                type: 'suspension',
                message: `Votre compte a été suspendu pour ${CANCELLATION_POLICY.SUSPENSION_DAYS} jours en raison de trop d'annulations`,
                suspendedUntil,
            };
        } else if (totalCancellations >= CANCELLATION_POLICY.WARNING_THRESHOLD) {
            // Avertissement
            worker.workerProfile.warningCount = (worker.workerProfile.warningCount || 0) + 1;

            const remainingBeforeSuspension = CANCELLATION_POLICY.SUSPENSION_THRESHOLD - totalCancellations;
            consequence = {
                type: 'warning',
                message: `Avertissement: Vous avez ${totalCancellations} annulations. Encore ${remainingBeforeSuspension} et votre compte sera suspendu.`,
                warningCount: worker.workerProfile.warningCount,
            };
        }

        await worker.save();

        // Notifier le client
        await Notification.notifyReservationCancelled(
            reservation,
            `Annulée par le déneigeur: ${fullReason}`
        );

        // Notifier le déneigeur de la conséquence
        if (consequence) {
            await Notification.create({
                userId: worker._id,
                type: consequence.type === 'suspension' ? 'systemNotification' : 'systemNotification',
                title: consequence.type === 'suspension' ? '⚠️ Compte suspendu' : '⚠️ Avertissement',
                message: consequence.message,
                priority: 'high',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Réservation annulée. Vous ne serez pas payé pour cette tâche.',
            reservation: {
                id: reservation._id,
                status: reservation.status,
                cancelledAt: reservation.cancelledAt,
                cancelReason: reservation.cancelReason,
            },
            consequence,
            stats: {
                totalCancellations: worker.workerProfile.totalCancellations,
                warningCount: worker.workerProfile.warningCount,
                isSuspended: worker.workerProfile.isSuspended,
            },
        });

    } catch (error) {
        console.error('Erreur lors de l\'annulation par le déneigeur:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'annulation',
        });
    }
});

/**
 * @route   PATCH /api/reservations/:id/cancel-by-client
 * @desc    Annulation par le client - avec pénalités selon le statut
 * @access  Private (Client)
 */
router.patch('/:id/cancel-by-client', protect, async (req, res) => {
    try {
        const { reason } = req.body;

        const reservation = await Reservation.findOne({
            _id: req.params.id,
            userId: req.user.id,
            status: { $nin: ['completed', 'cancelled'] },
        }).populate('workerId', 'firstName lastName');

        if (!reservation) {
            return res.status(404).json({
                success: false,
                message: 'Réservation non trouvée ou déjà terminée/annulée',
            });
        }

        const previousStatus = reservation.status;
        let cancellationFeePercent = 0;
        let cancellationFeeAmount = 0;
        let refundAmount = 0;
        let message = '';

        // Calculer les frais selon le statut
        switch (previousStatus) {
            case 'pending':
                // Pas encore assigné - remboursement complet
                cancellationFeePercent = 0;
                refundAmount = reservation.paymentStatus === 'paid' ? reservation.totalPrice : 0;
                message = 'Réservation annulée. Remboursement complet.';
                break;

            case 'assigned':
                // Assigné mais pas en route - remboursement complet
                cancellationFeePercent = 0;
                refundAmount = reservation.paymentStatus === 'paid' ? reservation.totalPrice : 0;
                message = 'Réservation annulée. Remboursement complet.';
                break;

            case 'enRoute':
                // Déneigeur en route - 50% de frais
                cancellationFeePercent = CANCELLATION_POLICY.EN_ROUTE_FEE_PERCENT;
                cancellationFeeAmount = reservation.totalPrice * (cancellationFeePercent / 100);
                refundAmount = reservation.paymentStatus === 'paid'
                    ? reservation.totalPrice - cancellationFeeAmount
                    : 0;
                message = `Réservation annulée. Le déneigeur était en route, vous êtes facturé ${cancellationFeePercent}% (${cancellationFeeAmount.toFixed(2)}$).`;
                break;

            case 'inProgress':
                // Travail en cours - 100% facturé
                cancellationFeePercent = CANCELLATION_POLICY.IN_PROGRESS_FEE_PERCENT;
                cancellationFeeAmount = reservation.totalPrice;
                refundAmount = 0;
                message = `Réservation annulée. Le travail avait commencé, vous êtes facturé ${cancellationFeePercent}% (${cancellationFeeAmount.toFixed(2)}$).`;
                break;

            default:
                return res.status(400).json({
                    success: false,
                    message: 'Cette réservation ne peut pas être annulée',
                });
        }

        // Mettre à jour la réservation
        reservation.status = 'cancelled';
        reservation.cancelledAt = new Date();
        reservation.cancelledBy = 'client';
        reservation.cancelReason = reason || 'Annulée par le client';
        reservation.cancellationFee = {
            amount: cancellationFeeAmount,
            percentage: cancellationFeePercent,
            charged: cancellationFeeAmount > 0,
            chargedAt: cancellationFeeAmount > 0 ? new Date() : null,
        };
        reservation.refundAmount = refundAmount;
        reservation.refundedAt = refundAmount > 0 ? new Date() : null;

        // Mettre à jour le statut de paiement
        if (reservation.paymentStatus === 'paid') {
            if (refundAmount === reservation.totalPrice) {
                reservation.paymentStatus = 'refunded';
            } else if (refundAmount > 0) {
                reservation.paymentStatus = 'partially_refunded';
            }
            // Si refundAmount === 0, garder 'paid' car le client paie tout
        }

        await reservation.save();

        // Traiter le remboursement via Stripe si applicable
        let stripeRefund = null;
        if (refundAmount > 0 && reservation.paymentIntentId) {
            try {
                stripeRefund = await stripe.refunds.create({
                    payment_intent: reservation.paymentIntentId,
                    amount: Math.round(refundAmount * 100), // En cents
                    reason: 'requested_by_customer',
                });
                console.log('✅ Remboursement Stripe créé:', stripeRefund.id);
            } catch (stripeError) {
                console.error('❌ Erreur remboursement Stripe:', stripeError);
                // Continuer même si le remboursement échoue (à traiter manuellement)
            }
        }

        // Payer le déneigeur si des frais sont appliqués et qu'il était assigné
        if (cancellationFeeAmount > 0 && reservation.workerId) {
            const platformFee = cancellationFeeAmount * 0.25; // 25% plateforme
            const workerAmount = cancellationFeeAmount * 0.75; // 75% déneigeur

            reservation.payout = {
                status: 'pending',
                workerAmount,
                platformFee,
                stripeFee: 0,
            };
            await reservation.save();

            // TODO: Transférer au déneigeur via Stripe Connect si configuré
        }

        // Notifier le déneigeur si assigné
        if (reservation.workerId) {
            await Notification.create({
                userId: reservation.workerId._id || reservation.workerId,
                type: 'reservationCancelled',
                title: '❌ Réservation annulée par le client',
                message: cancellationFeeAmount > 0
                    ? `Le client a annulé. Vous recevrez ${(cancellationFeeAmount * 0.75).toFixed(2)}$ de compensation.`
                    : 'Le client a annulé la réservation.',
                priority: 'high',
                metadata: {
                    reservationId: reservation._id,
                    cancellationFee: cancellationFeeAmount,
                    workerCompensation: cancellationFeeAmount * 0.75,
                },
            });
        }

        // Notifier le client
        await Notification.create({
            userId: req.user.id,
            type: 'reservationCancelled',
            title: '✅ Réservation annulée',
            message: message,
            priority: 'medium',
            metadata: {
                reservationId: reservation._id,
                cancellationFee: cancellationFeeAmount,
                refundAmount,
            },
        });

        res.status(200).json({
            success: true,
            message,
            reservation: {
                id: reservation._id,
                status: reservation.status,
                previousStatus,
                cancelledAt: reservation.cancelledAt,
                cancelReason: reservation.cancelReason,
            },
            billing: {
                originalPrice: reservation.totalPrice,
                cancellationFeePercent,
                cancellationFeeAmount,
                refundAmount,
                finalCharge: cancellationFeeAmount,
            },
            stripeRefund: stripeRefund ? {
                id: stripeRefund.id,
                status: stripeRefund.status,
            } : null,
        });

    } catch (error) {
        console.error('Erreur lors de l\'annulation par le client:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'annulation',
        });
    }
});

/**
 * @route   GET /api/reservations/worker/cancellation-reasons
 * @desc    Obtenir la liste des raisons valables d'annulation pour les déneigeurs
 * @access  Private (Worker)
 */
router.get('/worker/cancellation-reasons', protect, (req, res) => {
    const reasons = {
        vehicle_breakdown: {
            code: 'vehicle_breakdown',
            label: 'Panne de véhicule',
            description: 'Mon véhicule est en panne ou a un problème mécanique',
        },
        medical_emergency: {
            code: 'medical_emergency',
            label: 'Urgence médicale',
            description: 'J\'ai une urgence médicale personnelle',
        },
        severe_weather: {
            code: 'severe_weather',
            label: 'Conditions météo dangereuses',
            description: 'Les conditions météo rendent le trajet dangereux',
        },
        road_blocked: {
            code: 'road_blocked',
            label: 'Route bloquée',
            description: 'La route vers le client est bloquée ou inaccessible',
        },
        family_emergency: {
            code: 'family_emergency',
            label: 'Urgence familiale',
            description: 'J\'ai une urgence familiale',
        },
        equipment_failure: {
            code: 'equipment_failure',
            label: 'Équipement défaillant',
            description: 'Mon équipement de déneigement est défaillant',
        },
        other: {
            code: 'other',
            label: 'Autre raison',
            description: 'Autre raison (nécessite une description)',
            requiresDescription: true,
        },
    };

    res.json({
        success: true,
        reasons,
        policy: {
            warningThreshold: CANCELLATION_POLICY.WARNING_THRESHOLD,
            suspensionThreshold: CANCELLATION_POLICY.SUSPENSION_THRESHOLD,
            suspensionDays: CANCELLATION_POLICY.SUSPENSION_DAYS,
            note: 'Les annulations fréquentes peuvent entraîner des avertissements et une suspension temporaire.',
        },
    });
});

/**
 * @route   GET /api/reservations/client/cancellation-policy
 * @desc    Obtenir la politique d'annulation pour les clients
 * @access  Private
 */
router.get('/client/cancellation-policy', protect, (req, res) => {
    res.json({
        success: true,
        policy: {
            pending: {
                status: 'pending',
                label: 'En attente',
                feePercent: 0,
                description: 'Remboursement complet - Aucun déneigeur assigné',
            },
            assigned: {
                status: 'assigned',
                label: 'Assignée',
                feePercent: 0,
                description: 'Remboursement complet - Déneigeur pas encore en route',
            },
            enRoute: {
                status: 'enRoute',
                label: 'En route',
                feePercent: CANCELLATION_POLICY.EN_ROUTE_FEE_PERCENT,
                description: `Frais de ${CANCELLATION_POLICY.EN_ROUTE_FEE_PERCENT}% - Le déneigeur est en route vers vous`,
            },
            inProgress: {
                status: 'inProgress',
                label: 'En cours',
                feePercent: CANCELLATION_POLICY.IN_PROGRESS_FEE_PERCENT,
                description: `Frais de ${CANCELLATION_POLICY.IN_PROGRESS_FEE_PERCENT}% - Le travail a déjà commencé`,
            },
        },
    });
});

module.exports = router;