/**
 * Utilitaires de gestion des devises
 * Centralise toutes les conversions et calculs monétaires
 */

// Configuration des frais
const STRIPE_FEE_PERCENT = 0.029; // 2.9%
const STRIPE_FEE_FIXED = 0.30; // $0.30

/**
 * Convertit un montant en dollars vers des cents
 * @param {number} dollars - Montant en dollars
 * @returns {number} Montant en cents (entier)
 */
const toCents = (dollars) => {
    if (!Number.isFinite(dollars) || isNaN(dollars)) {
        throw new Error('Le montant doit être un nombre valide');
    }
    return Math.round(dollars * 100);
};

/**
 * Convertit un montant en cents vers des dollars
 * @param {number} cents - Montant en cents
 * @returns {number} Montant en dollars (arrondi à 2 décimales)
 */
const toDollars = (cents) => {
    if (!Number.isFinite(cents) || isNaN(cents)) {
        throw new Error('Le montant doit être un nombre valide');
    }
    return Math.round(cents) / 100;
};

/**
 * Arrondit un montant à 2 décimales
 * @param {number} amount - Montant à arrondir
 * @returns {number} Montant arrondi
 */
const roundMoney = (amount) => {
    if (!Number.isFinite(amount) || isNaN(amount)) {
        return 0;
    }
    return Math.round(amount * 100) / 100;
};

/**
 * Calcule les frais Stripe estimés pour un montant
 * @param {number} dollars - Montant total en dollars
 * @returns {number} Frais Stripe estimés en dollars
 */
const calculateStripeFee = (dollars) => {
    if (!Number.isFinite(dollars) || isNaN(dollars) || dollars <= 0) {
        return 0;
    }
    return roundMoney((dollars * STRIPE_FEE_PERCENT) + STRIPE_FEE_FIXED);
};

/**
 * Calcule la répartition des paiements
 * @param {number} totalAmount - Montant total en dollars
 * @param {number} platformFeePercent - Pourcentage de frais de plateforme (ex: 0.25 pour 25%)
 * @param {number} tipAmount - Montant du pourboire en dollars (optionnel)
 * @returns {Object} Répartition des montants
 */
const calculatePaymentBreakdown = (totalAmount, platformFeePercent, tipAmount = 0) => {
    if (!Number.isFinite(totalAmount) || isNaN(totalAmount) || totalAmount <= 0) {
        throw new Error('Le montant total doit être un nombre positif');
    }

    if (!Number.isFinite(platformFeePercent) || isNaN(platformFeePercent) ||
        platformFeePercent < 0 || platformFeePercent > 1) {
        throw new Error('Le pourcentage de frais doit être entre 0 et 1');
    }

    const safeTip = Number.isFinite(tipAmount) && !isNaN(tipAmount) ? tipAmount : 0;

    const platformFee = roundMoney(totalAmount * platformFeePercent);
    const workerAmount = roundMoney(totalAmount - platformFee + safeTip);
    const stripeFee = calculateStripeFee(totalAmount + safeTip);
    const grossTotal = roundMoney(totalAmount + safeTip);

    return {
        grossTotal,
        platformFee,
        workerAmount,
        stripeFee,
        platformFeeNet: roundMoney(platformFee - stripeFee),
        tipAmount: roundMoney(safeTip),
    };
};

/**
 * Valide qu'un montant est un nombre valide et positif
 * @param {any} amount - Valeur à valider
 * @param {string} fieldName - Nom du champ pour le message d'erreur
 * @returns {number} Montant validé
 * @throws {Error} Si le montant n'est pas valide
 */
const validateAmount = (amount, fieldName = 'montant') => {
    const parsed = parseFloat(amount);

    if (isNaN(parsed) || !Number.isFinite(parsed)) {
        throw new Error(`Le ${fieldName} doit être un nombre valide`);
    }

    if (parsed < 0) {
        throw new Error(`Le ${fieldName} ne peut pas être négatif`);
    }

    return parsed;
};

/**
 * Formate un montant en devise canadienne
 * @param {number} amount - Montant en dollars
 * @returns {string} Montant formaté (ex: "25.99 $")
 */
const formatCAD = (amount) => {
    if (!Number.isFinite(amount) || isNaN(amount)) {
        return '0.00 $';
    }
    return `${roundMoney(amount).toFixed(2)} $`;
};

module.exports = {
    STRIPE_FEE_PERCENT,
    STRIPE_FEE_FIXED,
    toCents,
    toDollars,
    roundMoney,
    calculateStripeFee,
    calculatePaymentBreakdown,
    validateAmount,
    formatCAD,
};
