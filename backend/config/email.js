const { Resend } = require('resend');

// Validation de la configuration email en production
const isProduction = process.env.NODE_ENV === 'production';
const isTest = process.env.NODE_ENV === 'test';

// Initialiser Resend de manière lazy pour éviter les erreurs pendant les tests
let resend = null;
const getResend = () => {
    if (!resend) {
        const apiKey = process.env.RESEND_API_KEY || 'test_key';

        // Validation critique en production
        if (isProduction && (!apiKey || apiKey === 'test_key')) {
            console.error('[CRITICAL] RESEND_API_KEY non configurée en production!');
            throw new Error('RESEND_API_KEY doit être configurée en production');
        }

        resend = new Resend(apiKey);
    }
    return resend;
};

// Valider l'adresse email d'envoi
const getEmailFrom = () => {
    const emailFrom = process.env.EMAIL_FROM;

    // En production, interdire l'utilisation de l'adresse de test Resend
    if (isProduction && (!emailFrom || emailFrom.includes('resend.dev'))) {
        console.error('[CRITICAL] EMAIL_FROM non configurée correctement en production!');
        throw new Error('EMAIL_FROM doit être une adresse email valide en production (pas resend.dev)');
    }

    return emailFrom || 'Deneige Auto <onboarding@resend.dev>';
};

// Envoyer un email
const sendEmail = async (options) => {
    console.log('\n[*] Préparation de l\'envoi d\'email avec Resend...');
    console.log('[*] Destinataire:', options.email);
    console.log('[*] Sujet:', options.subject);

    try {
        console.log('[*] Envoi de l\'email en cours...');
        const { data, error } = await getResend().emails.send({
            from: getEmailFrom(),
            to: [options.email],
            subject: options.subject,
            html: options.html,
        });

        if (error) {
            console.error('[X] Erreur Resend:', error);
            throw new Error(error.message);
        }

        console.log('[OK] Email envoyé avec succes:', data.id);
        return data;
    } catch (error) {
        console.error('[X] Erreur lors de l\'envoi de l\'email:', error);
        console.error('[X] Message:', error.message);
        throw error;
    }
};

// Template d'email pour la réinitialisation de mot de passe
const sendPasswordResetEmail = async (user, resetToken) => {
    console.log('[*] Génération du template email pour:', user.email);

    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
    console.log('[*] URL de réinitialisation:', resetUrl);

    const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                }
                .container {
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: #f4f4f4;
                }
                .email-content {
                    background-color: white;
                    padding: 30px;
                    border-radius: 10px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                .header {
                    text-align: center;
                    color: #1E3A8A;
                    margin-bottom: 30px;
                }
                .button {
                    display: inline-block;
                    padding: 12px 30px;
                    background-color: #3B82F6;
                    color: #ffffff !important;
                    text-decoration: none;
                    border-radius: 5px;
                    margin: 20px 0;
                    font-weight: bold;
                    mso-padding-alt: 0;
                }
                .footer {
                    text-align: center;
                    color: #666;
                    font-size: 12px;
                    margin-top: 30px;
                }
                .warning {
                    background-color: #FFF3CD;
                    border-left: 4px solid #FFA000;
                    padding: 15px;
                    margin: 20px 0;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="email-content">
                    <div class="header">
                        <h1>❄️ Déneige Auto</h1>
                        <h2>Réinitialisation de mot de passe</h2>
                    </div>

                    <p>Bonjour <strong>${user.firstName} ${user.lastName}</strong>,</p>

                    <p>Vous avez demandé la réinitialisation de votre mot de passe pour votre compte Déneige Auto.</p>

                    <p>Cliquez sur le bouton ci-dessous pour réinitialiser votre mot de passe :</p>

                    <div style="text-align: center; margin: 30px 0;">
                        <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center">
                            <tr>
                                <td style="background-color: #3B82F6; border-radius: 5px;">
                                    <a href="${resetUrl}" target="_blank" style="display: inline-block; padding: 14px 32px; font-size: 16px; font-weight: bold; color: #ffffff; text-decoration: none; border-radius: 5px;">
                                        Réinitialiser mon mot de passe
                                    </a>
                                </td>
                            </tr>
                        </table>
                    </div>

                    <p><strong>Si le bouton ne fonctionne pas</strong>, copiez ce lien dans votre navigateur :</p>
                    <div style="background-color: #F3F4F6; padding: 15px; border-radius: 8px; margin: 15px 0;">
                        <a href="${resetUrl}" style="word-break: break-all; color: #3B82F6; font-size: 14px;">${resetUrl}</a>
                    </div>

                    <div class="warning">
                        <p><strong>⚠️ Important :</strong></p>
                        <ul>
                            <li>Ce lien expire dans <strong>10 minutes</strong></li>
                            <li>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email</li>
                            <li>Votre mot de passe restera inchangé</li>
                        </ul>
                    </div>

                    <div class="footer">
                        <p>Cet email a été envoyé par Déneige Auto</p>
                        <p>Si vous avez des questions, contactez-nous à support@deneige-auto.ca</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
    `;

    await sendEmail({
        email: user.email,
        subject: '🔐 Réinitialisation de votre mot de passe - Déneige Auto',
        html,
    });
    console.log('[OK] Email de réinitialisation traité');
};

module.exports = {
    sendEmail,
    sendPasswordResetEmail,
};
