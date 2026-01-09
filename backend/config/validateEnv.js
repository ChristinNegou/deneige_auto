/**
 * Validation des variables d'environnement au démarrage
 * Lance une erreur si une variable critique est manquante
 */

const requiredEnvVars = {
  // Base de données
  MONGODB_URI: {
    required: true,
    description: 'URI de connexion MongoDB',
  },

  // Authentification
  JWT_SECRET: {
    required: true,
    description: 'Secret pour signer les tokens JWT',
    validate: (value) => {
      if (value.length < 32) {
        return 'JWT_SECRET doit avoir au moins 32 caractères';
      }
      if (value.includes('votre_') || value.includes('a_changer')) {
        return 'JWT_SECRET contient une valeur placeholder - générez un vrai secret';
      }
      return null;
    },
  },

  // Stripe
  STRIPE_SECRET_KEY: {
    required: true,
    description: 'Clé secrète Stripe',
    validate: (value) => {
      if (!value.startsWith('sk_test_') && !value.startsWith('sk_live_')) {
        return 'STRIPE_SECRET_KEY doit commencer par sk_test_ ou sk_live_';
      }
      return null;
    },
  },
  STRIPE_PUBLISHABLE_KEY: {
    required: true,
    description: 'Clé publique Stripe',
    validate: (value) => {
      if (!value.startsWith('pk_test_') && !value.startsWith('pk_live_')) {
        return 'STRIPE_PUBLISHABLE_KEY doit commencer par pk_test_ ou pk_live_';
      }
      return null;
    },
  },

  // Twilio (SMS)
  TWILIO_ACCOUNT_SID: {
    required: false, // Optionnel si pas de SMS
    description: 'Account SID Twilio',
    validate: (value) => {
      if (value && !value.startsWith('AC')) {
        return 'TWILIO_ACCOUNT_SID doit commencer par AC';
      }
      return null;
    },
  },
  TWILIO_AUTH_TOKEN: {
    required: false,
    description: 'Auth Token Twilio',
  },
  TWILIO_PHONE_NUMBER: {
    required: false,
    description: 'Numéro de téléphone Twilio',
  },

  // Email
  EMAIL_HOST: {
    required: false,
    description: 'Serveur SMTP',
  },
  EMAIL_USER: {
    required: false,
    description: 'Utilisateur SMTP',
  },
  EMAIL_PASSWORD: {
    required: false,
    description: 'Mot de passe SMTP',
  },
};

const optionalEnvVars = [
  'PORT',
  'NODE_ENV',
  'ALLOWED_ORIGINS',
  'FRONTEND_URL',
  'APP_URL',
  'FIREBASE_PROJECT_ID',
];

/**
 * Valide les variables d'environnement
 * @param {boolean} exitOnError - Quitter le processus si erreur (default: true)
 * @returns {Object} - { valid: boolean, errors: string[], warnings: string[] }
 */
function validateEnv(exitOnError = true) {
  const errors = [];
  const warnings = [];

  console.log('\n🔐 Validation des variables d\'environnement...\n');

  // Vérifier les variables requises
  for (const [key, config] of Object.entries(requiredEnvVars)) {
    const value = process.env[key];

    if (!value || value.trim() === '') {
      if (config.required) {
        errors.push(`❌ ${key} est requis (${config.description})`);
      } else {
        warnings.push(`⚠️  ${key} non configuré (${config.description})`);
      }
      continue;
    }

    // Validation personnalisée
    if (config.validate) {
      const validationError = config.validate(value);
      if (validationError) {
        errors.push(`❌ ${key}: ${validationError}`);
        continue;
      }
    }

    // Masquer la valeur pour le log
    const maskedValue = value.substring(0, 8) + '...';
    console.log(`   ✓ ${key} = ${maskedValue}`);
  }

  // Afficher les warnings
  if (warnings.length > 0) {
    console.log('\n⚠️  Avertissements:');
    warnings.forEach(w => console.log(`   ${w}`));
  }

  // Afficher les erreurs
  if (errors.length > 0) {
    console.log('\n❌ Erreurs de configuration:');
    errors.forEach(e => console.log(`   ${e}`));
    console.log('\n💡 Conseil: Copiez .env.example vers .env et configurez vos clés');

    if (exitOnError) {
      console.log('\n🛑 Arrêt du serveur - Corrigez les erreurs ci-dessus\n');
      process.exit(1);
    }
  } else {
    console.log('\n✅ Configuration validée!\n');
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Vérifie si on est en mode production avec des clés de test
 */
function checkProductionKeys() {
  if (process.env.NODE_ENV === 'production') {
    const stripeKey = process.env.STRIPE_SECRET_KEY || '';

    if (stripeKey.startsWith('sk_test_')) {
      console.log('\n⚠️  ATTENTION: Vous utilisez des clés Stripe TEST en production!');
      console.log('   Les paiements ne seront pas réels.\n');
    }
  }
}

module.exports = {
  validateEnv,
  checkProductionKeys,
};
