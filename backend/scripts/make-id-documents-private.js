/**
 * Rend privees les pieces d'identite envoyees avant le correctif du
 * 2026-11-18 (elles etaient publiques, dans le dossier des photos de
 * deneigement).
 *
 * Pour chaque document (recto, verso, selfie) pas encore prive :
 *   - Cloudinary : passage en type "authenticated" et deplacement dans
 *     deneige-auto/verification/<userId>/ (l'ancienne URL publique cesse
 *     de fonctionner) ;
 *   - base de donnees : publicId, url et private: true mis a jour.
 *
 * Par defaut, n'affiche que ce qui serait fait. Pour appliquer :
 *   node scripts/make-id-documents-private.js --apply
 *
 * A lancer avec les variables de l'environnement vise (MONGODB_URI et
 * CLOUDINARY_*), par exemple en production : railway run node scripts/...
 */

require('dotenv').config();
const mongoose = require('mongoose');
const { cloudinary } = require('../config/cloudinary');
const User = require('../models/User');

const APPLY = process.argv.includes('--apply');
const KINDS = ['idFront', 'idBack', 'selfie'];

const baseName = (publicId) => publicId.split('/').pop();

async function makePrivate(user, kind, doc) {
    const target = `deneige-auto/verification/${user._id}/${kind}-${baseName(doc.publicId)}`;
    if (!APPLY) {
        console.log(`  [simulation] ${kind}: ${doc.publicId} -> ${target} (privé)`);
        return 'simulated';
    }
    const result = await cloudinary.uploader.rename(doc.publicId, target, {
        type: 'upload',
        to_type: 'authenticated',
        resource_type: 'image',
        overwrite: false,
    });
    await User.updateOne(
        { _id: user._id },
        {
            $set: {
                [`workerProfile.identityVerification.documents.${kind}.publicId`]: result.public_id,
                [`workerProfile.identityVerification.documents.${kind}.url`]: result.secure_url,
                [`workerProfile.identityVerification.documents.${kind}.private`]: true,
            },
        },
    );
    console.log(`  ✓ ${kind}: ${doc.publicId} -> ${result.public_id}`);
    return 'done';
}

async function main() {
    if (!process.env.MONGODB_URI || !process.env.CLOUDINARY_CLOUD_NAME) {
        console.error('MONGODB_URI et CLOUDINARY_* sont requis.');
        process.exit(1);
    }
    await mongoose.connect(process.env.MONGODB_URI);
    console.log(`Base : ${mongoose.connection.host}/${mongoose.connection.name}`);
    console.log(`Cloudinary : ${process.env.CLOUDINARY_CLOUD_NAME}`);
    console.log(APPLY ? 'Mode : APPLICATION\n' : 'Mode : simulation (ajoutez --apply pour appliquer)\n');

    const users = await User.find({
        role: 'snowWorker',
        $or: KINDS.map((k) => ({
            [`workerProfile.identityVerification.documents.${k}.publicId`]: { $exists: true, $ne: null },
            [`workerProfile.identityVerification.documents.${k}.private`]: { $ne: true },
        })),
    }).select('firstName lastName workerProfile.identityVerification.documents');

    const counts = { done: 0, simulated: 0, failed: 0 };
    for (const user of users) {
        console.log(`${user.firstName} ${user.lastName} (${user._id})`);
        const documents = user.workerProfile.identityVerification.documents;
        for (const kind of KINDS) {
            const doc = documents?.[kind];
            if (!doc?.publicId || doc.private) continue;
            try {
                counts[await makePrivate(user, kind, doc)]++;
            } catch (error) {
                counts.failed++;
                console.error(`  ✗ ${kind}: ${error.message}`);
            }
        }
    }

    console.log(`\n${users.length} déneigeur(s) concerné(s).`,
        APPLY ? `${counts.done} document(s) rendus privés, ${counts.failed} échec(s).`
            : `${counts.simulated} document(s) à rendre privés.`);
    await mongoose.disconnect();
    process.exit(counts.failed ? 1 : 0);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
