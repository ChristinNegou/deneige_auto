/**
 * Script pour créer ou promouvoir un utilisateur admin
 * Usage: node scripts/create-admin.js [email]
 *
 * Exemples:
 *   node scripts/create-admin.js                    # Crée admin@deneige-auto.com
 *   node scripts/create-admin.js mon@email.com     # Promeut cet email en admin
 */

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/deneige_auto';

// Schéma simplifié pour ce script
const userSchema = new mongoose.Schema({
    email: String,
    password: String,
    firstName: String,
    lastName: String,
    phoneNumber: String,
    phoneVerified: Boolean,
    role: String,
    isActive: Boolean,
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

async function createOrPromoteAdmin() {
    try {
        console.log('Connexion à MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('Connecté!\n');

        const emailArg = process.argv[2];

        if (emailArg) {
            // Promouvoir un utilisateur existant
            const user = await User.findOne({ email: emailArg.toLowerCase() });

            if (!user) {
                console.log(`Utilisateur avec email "${emailArg}" non trouvé.`);
                console.log('\nUtilisateurs disponibles:');
                const users = await User.find({}, 'email firstName lastName role');
                users.forEach(u => {
                    console.log(`  - ${u.email} (${u.firstName} ${u.lastName}) - Role: ${u.role}`);
                });
                process.exit(1);
            }

            if (user.role === 'admin') {
                console.log(`${user.email} est déjà admin!`);
            } else {
                user.role = 'admin';
                await user.save();
                console.log(`✅ ${user.email} est maintenant ADMIN!`);
            }
        } else {
            // Créer un nouveau compte admin
            const adminEmail = 'admin@deneige-auto.com';
            const adminPassword = 'Admin123!';

            const existingAdmin = await User.findOne({ email: adminEmail });

            if (existingAdmin) {
                if (existingAdmin.role !== 'admin') {
                    existingAdmin.role = 'admin';
                    await existingAdmin.save();
                    console.log(`✅ ${adminEmail} promu en admin!`);
                } else {
                    console.log(`${adminEmail} existe déjà comme admin.`);
                }
                console.log(`\n📧 Email: ${adminEmail}`);
                console.log(`🔑 Mot de passe: (celui que vous avez défini)`);
            } else {
                const hashedPassword = await bcrypt.hash(adminPassword, 12);

                await User.create({
                    email: adminEmail,
                    password: hashedPassword,
                    firstName: 'Admin',
                    lastName: 'Deneige',
                    phoneNumber: '+1 000-000-0000',
                    phoneVerified: true,
                    role: 'admin',
                    isActive: true,
                });

                console.log('✅ Compte admin créé avec succès!\n');
                console.log('═'.repeat(40));
                console.log('📧 Email:       admin@deneige-auto.com');
                console.log('🔑 Mot de passe: Admin123!');
                console.log('═'.repeat(40));
                console.log('\n⚠️  Changez ce mot de passe après la première connexion!');
            }
        }

        // Afficher tous les admins
        console.log('\n📋 Liste des administrateurs:');
        const admins = await User.find({ role: 'admin' }, 'email firstName lastName');
        admins.forEach(a => {
            console.log(`   - ${a.email} (${a.firstName} ${a.lastName})`);
        });

    } catch (error) {
        console.error('Erreur:', error.message);
    } finally {
        await mongoose.disconnect();
        console.log('\nDéconnecté de MongoDB.');
    }
}

createOrPromoteAdmin();
