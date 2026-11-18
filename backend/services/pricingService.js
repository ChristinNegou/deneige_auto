/**
 * Prix plancher d'une reservation, recalcule cote serveur.
 *
 * Le prix exact (taxes selon la province) est calcule dans l'application ;
 * le serveur verifie seulement que le montant recu n'est pas inferieur au
 * minimum possible pour ce service, afin qu'un client ne puisse pas fixer
 * lui-meme un prix derisoire.
 */
const { PRICING } = require('../config/constants');

/** Facteur le plus bas connu : pour un type inconnu, on reste prudent. */
const LOWEST_VEHICLE_FACTOR = 0.7;

/**
 * @param {Object} params
 * @param {string} [params.vehicleType] - type du vehicule (Vehicle.type)
 * @param {string} [params.parkingLevel] - niveau de la place (ParkingSpot.level)
 * @param {number} [params.snowDepthCm]
 * @param {string[]} [params.serviceOptions]
 * @returns {number} Total minimum accepte, en CAD, arrondi au cent inferieur
 */
const minimumTotal = ({ vehicleType, parkingLevel, snowDepthCm, serviceOptions = [] }) => {
    const vehicleFactor = PRICING.VEHICLE_FACTORS[vehicleType] ?? LOWEST_VEHICLE_FACTOR;
    const parkingFactor = parkingLevel ? (PRICING.PARKING_FACTORS[parkingLevel] ?? 0.6) : 1.0;

    let price = PRICING.BASE_PRICE * vehicleFactor * parkingFactor;
    if (snowDepthCm && snowDepthCm > 10) {
        price += (snowDepthCm - 10) * PRICING.PRICE_PER_CM_OVER_10;
    }
    for (const option of serviceOptions) {
        price += PRICING.OPTION_SURCHARGES[option] || 0;
    }
    price += PRICING.SERVICE_FEE + PRICING.INSURANCE_FEE;

    const withMinTax = price * (1 + PRICING.MIN_TAX_RATE);
    return Math.floor(withMinTax * 100) / 100;
};

module.exports = { minimumTotal };
