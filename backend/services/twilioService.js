/**
 * Service Twilio pour l'envoi et la vérification de codes SMS
 */

const twilio = require('twilio');

// Configuration Twilio
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER;

// Client Twilio (initialisé seulement si les credentials sont présents)
let client = null;

const initTwilioClient = () => {
    if (!client && accountSid && authToken) {
        client = twilio(accountSid, authToken);
    }
    return client;
};

/**
 * Génère un code de vérification à 6 chiffres
 * @returns {string} Code à 6 chiffres
 */
const generateVerificationCode = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Formate un numéro de téléphone au format E.164
 * @param {string} phoneNumber - Numéro de téléphone
 * @returns {string} Numéro formaté
 */
const formatPhoneNumber = (phoneNumber) => {
    // Supprimer tous les caractères non numériques sauf le +
    let cleaned = phoneNumber.replace(/[^\d+]/g, '');

    // Si le numéro ne commence pas par +, ajouter +1 (Canada/US)
    if (!cleaned.startsWith('+')) {
        // Si le numéro commence par 1, ajouter juste +
        if (cleaned.startsWith('1') && cleaned.length === 11) {
            cleaned = '+' + cleaned;
        } else if (cleaned.length === 10) {
            // Numéro à 10 chiffres, ajouter +1
            cleaned = '+1' + cleaned;
        }
    }

    return cleaned;
};

/**
 * Valide le format d'un numéro de téléphone
 * @param {string} phoneNumber - Numéro de téléphone
 * @returns {boolean} True si valide
 */
const isValidPhoneNumber = (phoneNumber) => {
    const formatted = formatPhoneNumber(phoneNumber);
    // Format E.164: +1 suivi de 10 chiffres pour Canada/US
    const phoneRegex = /^\+1[2-9]\d{9}$/;
    return phoneRegex.test(formatted);
};

/**
 * Envoie un code de vérification par SMS
 * @param {string} phoneNumber - Numéro de téléphone du destinataire
 * @param {string} code - Code de vérification
 * @returns {Promise<Object>} Résultat de l'envoi
 */
const sendVerificationCode = async (phoneNumber, code) => {
    const twilioClient = initTwilioClient();

    // Mode développement: simuler l'envoi si Twilio n'est pas configuré
    if (!twilioClient) {
        console.log('='.repeat(50));
        console.log('📱 MODE DÉVELOPPEMENT - SMS SIMULÉ');
        console.log(`📞 Numéro: ${phoneNumber}`);
        console.log(`🔐 Code de vérification: ${code}`);
        console.log('='.repeat(50));

        return {
            success: true,
            simulated: true,
            message: 'SMS simulé en mode développement',
            code: code // Retourner le code en dev pour faciliter les tests
        };
    }

    try {
        const formattedPhone = formatPhoneNumber(phoneNumber);

        const message = await twilioClient.messages.create({
            body: `Votre code de vérification Déneige Auto est: ${code}. Ce code expire dans 15 minutes.`,
            from: twilioPhoneNumber,
            to: formattedPhone
        });

        console.log(`SMS envoyé avec succès. SID: ${message.sid}`);

        return {
            success: true,
            simulated: false,
            messageSid: message.sid
        };
    } catch (error) {
        console.error('Erreur lors de l\'envoi du SMS:', error.message);
        throw new Error(`Erreur d'envoi SMS: ${error.message}`);
    }
};

/**
 * Vérifie si Twilio est correctement configuré
 * @returns {boolean} True si configuré
 */
const isTwilioConfigured = () => {
    return !!(accountSid && authToken && twilioPhoneNumber);
};

module.exports = {
    generateVerificationCode,
    formatPhoneNumber,
    isValidPhoneNumber,
    sendVerificationCode,
    isTwilioConfigured
};
