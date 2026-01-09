# Deploiement Backend - Railway

## Prerequisites

1. Compte Railway (https://railway.app)
2. Compte MongoDB Atlas pour la base de donnees production
3. Cles API configurees (Stripe, Twilio, Firebase)

## Etape 1 : Preparer MongoDB Atlas

1. Connectez-vous a https://cloud.mongodb.com
2. Creez un cluster (le tier gratuit M0 suffit pour commencer)
3. Creez un utilisateur de base de donnees avec mot de passe
4. Dans "Network Access", ajoutez `0.0.0.0/0` pour autoriser Railway
5. Copiez l'URI de connexion : `mongodb+srv://username:password@cluster.mongodb.net/deneige_auto`

## Etape 2 : Deploiement sur Railway

### Option A : Via GitHub (Recommande)

1. Connectez votre repo GitHub a Railway
2. Railway detectera automatiquement le fichier `railway.json`
3. Le deploiement se fera automatiquement a chaque push

### Option B : Via Railway CLI

```bash
# Installer Railway CLI
npm install -g @railway/cli

# Se connecter
railway login

# Initialiser le projet (depuis le dossier backend)
cd backend
railway init

# Deployer
railway up
```

## Etape 3 : Variables d'Environnement

Dans Railway Dashboard > Variables, ajoutez :

### Variables Requises

| Variable | Description | Exemple |
|----------|-------------|---------|
| `NODE_ENV` | Environnement | `production` |
| `MONGODB_URI` | URI MongoDB Atlas | `mongodb+srv://user:pass@cluster.mongodb.net/deneige_auto` |
| `JWT_SECRET` | Secret JWT (64+ caracteres) | Generer avec: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"` |
| `STRIPE_SECRET_KEY` | Cle secrete Stripe LIVE | `sk_live_xxx` |
| `STRIPE_PUBLISHABLE_KEY` | Cle publique Stripe LIVE | `pk_live_xxx` |

### Variables Optionnelles (SMS/Email/Notifications)

| Variable | Description | Exemple |
|----------|-------------|---------|
| `TWILIO_ACCOUNT_SID` | SID compte Twilio | `ACxxx` |
| `TWILIO_AUTH_TOKEN` | Token auth Twilio | `xxx` |
| `TWILIO_PHONE_NUMBER` | Numero Twilio | `+14388086873` |
| `EMAIL_HOST` | Serveur SMTP | `smtp.gmail.com` |
| `EMAIL_PORT` | Port SMTP | `587` |
| `EMAIL_USER` | Email SMTP | `votre_email@gmail.com` |
| `EMAIL_PASSWORD` | Mot de passe app Gmail | `xxxx xxxx xxxx xxxx` |
| `EMAIL_FROM` | Expediteur | `Deneige Auto <noreply@deneigeauto.com>` |
| `FIREBASE_PROJECT_ID` | ID projet Firebase | `deneigeauto-88d16` |
| `FIREBASE_SERVICE_ACCOUNT` | JSON Service Account | `{"type":"service_account",...}` |

### Variables CORS (Important!)

| Variable | Description | Exemple |
|----------|-------------|---------|
| `ALLOWED_ORIGINS` | Origines autorisees | `https://deneigeauto.com,https://www.deneigeauto.com` |
| `FRONTEND_URL` | URL frontend | `https://deneigeauto.com` |
| `APP_URL` | URL application | `https://deneigeauto.com` |

## Etape 4 : Verifier le Deploiement

1. Railway fournira une URL comme `https://deneige-auto-backend-production.up.railway.app`
2. Testez l'endpoint health : `GET /health`
3. Verifiez les logs dans Railway Dashboard

```bash
# Tester avec curl
curl https://votre-app.up.railway.app/health
```

Reponse attendue :
```json
{
  "success": true,
  "status": "healthy",
  "database": "connected",
  "uptime": 123.456
}
```

## Etape 5 : Mettre a Jour l'Application Flutter

Dans votre application Flutter, mettez a jour l'URL du backend :

```dart
// lib/core/config/app_config.dart
static String get baseUrl {
  if (kReleaseMode) {
    return 'https://votre-app.up.railway.app/api';
  }
  // URL de developpement local
  return 'http://10.0.2.2:3000/api';
}
```

## Commandes Utiles Railway

```bash
# Voir les logs en temps reel
railway logs

# Ouvrir le dashboard
railway open

# Voir les variables d'environnement
railway variables

# Redemarrer le service
railway up --detach
```

## Troubleshooting

### Erreur : "Database connection failed"
- Verifiez que `MONGODB_URI` est correct
- Verifiez que l'IP `0.0.0.0/0` est autorisee dans MongoDB Atlas

### Erreur : "JWT_SECRET validation failed"
- Le secret doit avoir au moins 32 caracteres
- Generez-en un nouveau : `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`

### Erreur : "CORS blocked"
- Ajoutez votre domaine frontend dans `ALLOWED_ORIGINS`

### Erreur : "Stripe key invalid"
- En production, utilisez les cles LIVE (`sk_live_`, `pk_live_`)
- Les cles TEST ne fonctionnent qu'en developpement

## Securite Production

- [ ] `NODE_ENV=production`
- [ ] JWT_SECRET unique et fort (64+ caracteres)
- [ ] Cles Stripe LIVE (pas TEST)
- [ ] MongoDB Atlas avec authentification
- [ ] ALLOWED_ORIGINS configure (pas `*`)
- [ ] HTTPS uniquement (Railway le fournit automatiquement)
