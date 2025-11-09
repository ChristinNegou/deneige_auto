const nodemailer = require('nodemailer');

// Créer un transporteur pour l'envoi d'emails
const createTransporter = () => {
    console.log('[*] Création du transporteur email...');
    console.log('[*] EMAIL_HOST:', process.env.EMAIL_HOST);
    console.log('[*] EMAIL_PORT:', process.env.EMAIL_PORT);
    console.log('[*] EMAIL_USER:', process.env.EMAIL_USER);
    console.log('[*] EMAIL_PASSWORD configuré:', !!process.env.EMAIL_PASSWORD);


    return nodemailer.createTransport({
        host: process.env.EMAIL_HOST,
        port: process.env.EMAIL_PORT,
        secure: false, // true pour 465, false pour les autres ports
        auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASSWORD,
        },
        debug: true, // Active les logs de debug
        logger: true, // Active le logger

    });
};

// Envoyer un email
const sendEmail = async (options) => {
    console.log('\n[*] Préparation de l\'envoi d\'email...');
    console.log('[*] Destinataire:', options.email);
    console.log('[*] Sujet:', options.subject);

    const transporter = createTransporter();

    const message = {
        from: process.env.EMAIL_FROM,
        to: options.email,
        subject: options.subject,
        html: options.html,
    };

    try {
        console.log('[*] Envoi de l\'email en cours...');
        const info = await transporter.sendMail(message);
        console.log('[OK] Email envoyé avec succes:', info.messageId);
        console.log('[OK] Message ID:', info.messageId);


        return info;
    } catch (error) {
        console.error('[X] Erreur lors de l\'envoi de l\'email:', error);
        console.error('[X] Message:', error.message);
        console.error('[X] Code:', error.code);
        console.error('[X] Détails complets:', error);


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
                    color: white !important;
                    text-decoration: none;
                    border-radius: 5px;
                    margin: 20px 0;
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
                    
                    <div style="text-align: center;">
                        <a href="${resetUrl}" class="button">Réinitialiser mon mot de passe</a>
                    </div>
                    
                    <p>Ou copiez-collez ce lien dans votre navigateur :</p>
                    <p style="word-break: break-all; color: #3B82F6;">${resetUrl}</p>
                    
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
                        <p>Si vous avez des questions, contactez-nous à support@deneigeauto.com</p>
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