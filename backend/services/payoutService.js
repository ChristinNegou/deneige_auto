/**
 * Versements aux deneigeurs : une seule regle pour tout le serveur.
 *
 * - Part du deneigeur pour un deneigement : WORKER_PERCENT (75 %) du prix,
 *   SANS le pourboire. Versee une seule fois (cle Stripe `payout_job_<id>`).
 * - Pourboire : 100 % au deneigeur, verse a part (cle `tip_job_<id>`), une
 *   fois paye par le client.
 * - Litige perdu par le deneigeur : sa part du montant rembourse est reprise
 *   (annulation du virement Stripe, ou versement en attente reduit).
 *
 * Compteurs du profil : totalEarnings = parts + pourboires gagnes,
 * mis a jour quand le deneigement est termine / le pourboire paye / la part
 * reprise, jamais au moment du virement (pas de double comptage).
 */

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Notification = require('../models/Notification');
const { WORKER_PERCENT, PLATFORM_FEE_PERCENT } = require('../config/constants');

const round2 = (n) => Math.round((n || 0) * 100) / 100;

/** Part du deneigeur pour un prix donne (hors pourboire). */
const workerShareOf = (totalPrice) => round2((totalPrice || 0) * WORKER_PERCENT);

/**
 * Paiement Stripe (charge) du client derriere un PaymentIntent. Le virement
 * qui s'y rattache (source_transaction) part des que l'argent de ce paiement
 * est disponible, au lieu d'exiger un solde disponible sur la plateforme :
 * l'argent des paiements reste "en attente" quelques jours chez Stripe.
 */
async function chargeIdOf(paymentIntentId) {
    if (!paymentIntentId) return null;
    try {
        const intent = await stripe.paymentIntents.retrieve(paymentIntentId);
        const charge = intent?.latest_charge;
        return typeof charge === 'string' ? charge : charge?.id || null;
    } catch (error) {
        console.error('[payout] Paiement source introuvable:', error.message);
        return null;
    }
}

/** Statuts ou la part du deneigeur est deja partie. */
const PAID_STATUSES = ['paid', 'completed'];

/**
 * Verse la part du deneigeur pour un deneigement termine. Sans compte Stripe
 * ou sans paiement du client, le versement reste en attente (repris plus tard
 * par l'activation du compte ou par l'admin).
 * @returns {Promise<{status: string, transferId?: string, amount?: number, error?: string}>}
 */
async function payoutReservation(reservation, worker) {
    const payout = reservation.payout || {};
    if (PAID_STATUSES.includes(payout.status) || ['reversed', 'cancelled'].includes(payout.status)) {
        return { status: 'already_done' };
    }
    if (!worker) worker = await User.findById(reservation.workerId);
    if (!worker) return { status: 'no_worker' };

    const share = workerShareOf(reservation.totalPrice);
    reservation.payout.workerAmount = share;
    reservation.payout.platformFee = round2((reservation.totalPrice || 0) * PLATFORM_FEE_PERCENT);

    if (!worker.workerProfile?.stripeConnectId) {
        reservation.payout.status = 'pending_account';
        reservation.payout.note = 'En attente de configuration du compte de paiement';
        await reservation.save();
        return { status: 'pending_account' };
    }
    if (reservation.paymentStatus !== 'paid') {
        reservation.payout.status = 'pending_payment';
        reservation.payout.note = 'En attente du paiement client';
        await reservation.save();
        return { status: 'pending_payment' };
    }

    try {
        const sourceCharge = await chargeIdOf(reservation.paymentIntentId);
        const transfer = await stripe.transfers.create(
            {
                amount: Math.round(share * 100),
                currency: 'cad',
                destination: worker.workerProfile.stripeConnectId,
                description: `Paiement pour réservation #${reservation._id}`,
                ...(sourceCharge && { source_transaction: sourceCharge }),
                metadata: {
                    kind: 'job',
                    reservationId: reservation._id.toString(),
                    workerId: worker._id.toString(),
                },
            },
            // v2 : virements rattaches au paiement du client (une cle deja
            // utilisee ne peut pas etre reprise avec d'autres parametres)
            { idempotencyKey: `payout_job_v2_${reservation._id}` },
        );

        reservation.payout.status = 'paid';
        reservation.payout.stripeTransferId = transfer.id;
        reservation.payout.paidAt = new Date();
        reservation.payout.error = null;
        reservation.payout.note = null;
        await reservation.save();

        await Transaction.create({
            type: 'payout',
            status: 'succeeded',
            amount: share,
            reservationId: reservation._id,
            toUserId: worker._id,
            stripeTransferId: transfer.id,
            description: `Paiement pour réservation #${reservation._id}`,
            processedAt: new Date(),
        }).catch((e) => console.error('[payout] Transaction non enregistrée:', e.message));

        await Notification.createNotification({
            userId: worker._id,
            type: 'paymentReceived',
            title: 'Paiement envoyé',
            message: `${share.toFixed(2).replace('.', ',')} $ ont été envoyés sur votre compte de paiement.`,
            reservationId: reservation._id,
            metadata: { amount: share, transferId: transfer.id },
        }).catch((e) => console.error('[payout] Notification non envoyée:', e.message));

        return { status: 'paid', transferId: transfer.id, amount: share };
    } catch (error) {
        console.error('[payout] Virement échoué:', error.message);
        reservation.payout.status = 'failed';
        reservation.payout.error = error.message;
        await reservation.save();
        return { status: 'failed', error: error.message };
    }
}

/**
 * Verse un pourboire deja paye par le client. Sans compte Stripe, il reste en
 * attente et part avec les versements en attente.
 */
async function payoutTip(reservation, worker) {
    const amount = round2(reservation.tipAmount);
    if (amount <= 0 || reservation.tipPayout?.status === 'paid') return { status: 'already_done' };
    if (!worker) worker = await User.findById(reservation.workerId);
    if (!worker?.workerProfile?.stripeConnectId) {
        reservation.tipPayout.status = 'pending';
        await reservation.save();
        return { status: 'pending' };
    }

    try {
        const sourceCharge = await chargeIdOf(reservation.tipPaymentIntentId);
        const transfer = await stripe.transfers.create(
            {
                amount: Math.round(amount * 100),
                currency: 'cad',
                destination: worker.workerProfile.stripeConnectId,
                description: `Pourboire pour réservation #${reservation._id}`,
                ...(sourceCharge && { source_transaction: sourceCharge }),
                metadata: {
                    kind: 'tip',
                    reservationId: reservation._id.toString(),
                    workerId: worker._id.toString(),
                },
            },
            { idempotencyKey: `tip_job_v2_${reservation._id}` },
        );
        reservation.tipPayout = { status: 'paid', stripeTransferId: transfer.id, paidAt: new Date(), error: null };
        await reservation.save();

        await Transaction.create({
            type: 'tip',
            status: 'succeeded',
            amount,
            reservationId: reservation._id,
            fromUserId: reservation.userId,
            toUserId: worker._id,
            stripeTransferId: transfer.id,
            description: `Pourboire pour réservation #${reservation._id}`,
            processedAt: new Date(),
        }).catch((e) => console.error('[payout] Transaction pourboire non enregistrée:', e.message));

        return { status: 'paid', transferId: transfer.id, amount };
    } catch (error) {
        console.error('[payout] Virement du pourboire échoué:', error.message);
        reservation.tipPayout.status = 'failed';
        reservation.tipPayout.error = error.message;
        await reservation.save();
        return { status: 'failed', error: error.message };
    }
}

/**
 * Reprend au deneigeur sa part d'un remboursement accorde au client apres un
 * litige perdu : 75 % du montant rembourse, au plus ce qui lui a ete attribue.
 * @returns {Promise<{recovered: number, method?: string, error?: string}>}
 */
async function recoverWorkerShare(reservation, refundAmount, reason) {
    const payout = reservation.payout || {};
    const attributed = payout.workerAmount || workerShareOf(reservation.totalPrice);
    const alreadyRecovered = payout.reversedAmount || 0;
    const transferred = PAID_STATUSES.includes(payout.status) || (payout.status === 'reversed' && payout.stripeTransferId);
    // Deja verse : workerAmount reste le montant vire, on deduit ce qui a ete
    // repris. Pas encore verse : workerAmount est deja reduit a chaque reprise.
    const remaining = transferred ? attributed - alreadyRecovered : attributed;
    const toRecover = round2(Math.min(round2(refundAmount * WORKER_PERCENT), remaining));
    if (toRecover <= 0) return { recovered: 0 };

    let method;
    if (transferred) {
        if (!payout.stripeTransferId) return { recovered: 0, error: 'Virement introuvable' };
        try {
            await stripe.transfers.createReversal(
                payout.stripeTransferId,
                {
                    amount: Math.round(toRecover * 100),
                    metadata: { reservationId: reservation._id.toString(), reason: reason || 'Litige' },
                },
                { idempotencyKey: `reversal_job_${reservation._id}_${Math.round((alreadyRecovered + toRecover) * 100)}` },
            );
            method = 'transfer_reversal';
        } catch (error) {
            console.error('[payout] Reprise de la part échouée:', error.message);
            reservation.payout.reversalError = error.message;
            await reservation.save();
            return { recovered: 0, error: error.message };
        }
    } else {
        // Pas encore verse : on reduit ce qui reste a verser
        method = 'withheld';
    }

    reservation.payout.reversedAmount = round2(alreadyRecovered + toRecover);
    reservation.payout.reversalError = null;
    if (method === 'withheld') {
        reservation.payout.workerAmount = round2(attributed - toRecover);
        if (reservation.payout.workerAmount <= 0) reservation.payout.status = 'cancelled';
    } else {
        reservation.payout.status = 'reversed';
    }
    await reservation.save();

    if (reservation.workerId) {
        await User.findByIdAndUpdate(
            reservation.workerId._id || reservation.workerId,
            { $inc: { 'workerProfile.totalEarnings': -toRecover } },
        );
        await Transaction.create({
            type: 'payout_reversal',
            status: 'succeeded',
            amount: toRecover,
            reservationId: reservation._id,
            fromUserId: reservation.workerId._id || reservation.workerId,
            stripeTransferId: payout.stripeTransferId || undefined,
            description: reason || 'Part reprise après un litige',
            processedAt: new Date(),
        }).catch((e) => console.error('[payout] Transaction de reprise non enregistrée:', e.message));
    }

    return { recovered: toRecover, method };
}

/**
 * Enregistre un pourboire que le client a paye (PaymentIntent de type "tip"
 * deja verifie) puis le verse au deneigeur. Sans danger si appele deux fois
 * (app + webhook) : un seul pourboire par reservation.
 * @returns {Promise<{ok: boolean, reservation?: object, duplicate?: boolean, conflict?: boolean}>}
 */
async function recordPaidTip(reservationId, amount, paymentIntentId) {
    const Reservation = require('../models/Reservation');
    const tip = round2(amount);

    const reservation = await Reservation.findOneAndUpdate(
        { _id: reservationId, status: 'completed', tipAmount: { $in: [0, null] }, tipPaymentIntentId: null },
        {
            $set: {
                tipAmount: tip,
                tipPaymentIntentId: paymentIntentId,
                'payout.tipAmount': tip,
                'tipPayout.status': 'pending',
            },
        },
        { new: true },
    ).populate('workerId', 'firstName lastName workerProfile');

    if (!reservation) {
        const existing = await Reservation.findById(reservationId).select('tipPaymentIntentId');
        if (existing?.tipPaymentIntentId === paymentIntentId) return { ok: true, duplicate: true, reservation: existing };
        // Un autre pourboire est deja enregistre : celui-ci doit etre rembourse
        return { ok: false, conflict: true };
    }

    const worker = reservation.workerId;
    if (worker) {
        await User.findByIdAndUpdate(worker._id, {
            $inc: {
                'workerProfile.totalTipsReceived': tip,
                'workerProfile.totalEarnings': tip,
            },
        });
        // Toujours dans sa liste ; en push seulement s'il garde le reglage
        const wantsPush = worker.workerProfile?.notificationPreferences?.tips !== false;
        await Notification[wantsPush ? 'createNotification' : 'create']({
            userId: worker._id,
            type: 'tipReceived',
            title: 'Pourboire reçu',
            message: `Un client vous a laissé un pourboire de ${tip.toFixed(2).replace('.', ',')} $.`,
            priority: 'high',
            reservationId: reservation._id,
            metadata: { tipAmount: tip },
        }).catch((e) => console.error('[tip] Notification non envoyée:', e.message));

        await payoutTip(reservation, worker);
    }

    return { ok: true, reservation };
}

module.exports = {
    recordPaidTip,
    workerShareOf,
    payoutReservation,
    payoutTip,
    recoverWorkerShare,
    PAID_STATUSES,
};
