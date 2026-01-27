# Deneige-Auto

Application communautaire de deneigement pour immeubles a logements. Met en relation les residents qui ont besoin de faire deneiger leur vehicule avec des deneigeurs disponibles dans leur secteur.

## Stack technique

| Couche | Technologies |
|--------|-------------|
| Mobile | Flutter 3.x, Dart, BLoC (flutter_bloc) |
| Backend | Node.js 18+, Express, MongoDB (Mongoose) |
| Temps reel | Socket.IO |
| Paiement | Stripe Connect |
| IA | Claude (Anthropic) — matching, analyse photo, prediction demande |
| Notifications | Firebase Cloud Messaging (FCM) |
| SMS | Twilio |
| Stockage | Cloudinary (images), Hive (cache local) |
| Localisation | Google Maps, Geolocator |
| Langues | Francais (principal), Anglais |

## Demarrage rapide

### Prerequis

- Flutter SDK >= 3.0.0
- Node.js >= 18.0.0
- MongoDB (local ou Atlas)
- Comptes : Stripe, Firebase, Twilio, Cloudinary, OpenWeatherMap

### Backend

```bash
cd backend
cp .env.example .env        # Configurer les variables d'environnement
npm install
npm run dev                  # Demarre sur le port 3000
```

### Application Flutter

```bash
flutter pub get
flutter run
```

Pour l'emulateur Android, le backend est accessible a `http://10.0.2.2:3000`.

## Architecture

### Flutter — Clean Architecture + BLoC

```
lib/
├── core/
│   ├── config/          # Configuration (URLs API, cles, tarifs, taxes)
│   ├── di/              # Injection de dependances (GetIt)
│   ├── network/         # Client HTTP Dio + intercepteurs JWT
│   ├── routing/         # Navigation centralisee (routes nommees)
│   ├── services/        # Services transversaux (GPS, analytics, push, socket)
│   ├── cache/           # Cache offline Hive + file de synchronisation
│   ├── errors/          # Exceptions et Failures (pattern Either)
│   └── theme/           # Theme sombre de l'application
│
├── features/            # 24 modules metier
│   ├── auth/            # Authentification (login, register, JWT, reset password)
│   ├── reservation/     # Creation et suivi de reservations (wizard 4 etapes)
│   ├── payment/         # Paiements Stripe, historique, remboursements
│   ├── snow_worker/     # Tableau de bord deneigeur (jobs, stats, disponibilite)
│   ├── notifications/   # Centre de notifications push
│   ├── ai_chat/         # Chat avec assistant IA (Claude)
│   ├── ai_features/     # Predictions meteo, suggestions IA
│   ├── disputes/        # Litiges client-deneigeur
│   ├── verification/    # Verification d'identite (piece + selfie)
│   ├── home/            # Accueil (meteo, reservations a venir)
│   ├── vehicule/        # Gestion des vehicules
│   ├── subscription/    # Abonnements (hebdo, mensuel, saisonnier)
│   ├── profile/         # Profil utilisateur et parametres
│   ├── support/         # Demandes de support client
│   ├── chat/            # Messagerie en temps reel
│   ├── admin/           # Panneau d'administration
│   ├── weather/         # Meteo (OpenWeatherMap)
│   └── ...              # settings, legal, activities, widgets, jobslist, client
│
├── l10n/                # Fichiers de traduction ARB (fr, en)
└── main.dart            # Point d'entree
```

Chaque feature suit le pattern Clean Architecture :
```
feature/
├── data/
│   ├── datasources/     # Appels API (Dio)
│   ├── models/          # Modeles avec serialisation JSON
│   └── repositories/    # Implementation (Either<Failure, T>)
├── domain/
│   ├── entities/        # Entites metier (classes Dart pures)
│   ├── repositories/    # Contrats / interfaces
│   └── usecases/        # Cas d'utilisation
└── presentation/
    ├── bloc/            # Gestion d'etat (Events → BLoC → States)
    ├── pages/           # Pages plein ecran
    └── widgets/         # Composants UI reutilisables
```

### Backend Node.js

```
backend/
├── config/              # Database, constantes, enums, prompts IA, email
├── middleware/           # Auth JWT, validation, rate limiting
├── models/              # Schemas Mongoose (User, Reservation, Vehicle, etc.)
├── routes/              # 16 fichiers de routes Express
│   ├── auth.js          # Inscription, connexion, profil
│   ├── reservations.js  # CRUD reservations, assignation, completion
│   ├── workers.js       # Jobs, disponibilite, stats deneigeur
│   ├── payments.js      # Stripe, remboursements, versements
│   ├── stripeConnect.js # Comptes Connect, comptes bancaires
│   ├── disputes.js      # Litiges et resolution
│   ├── admin.js         # Administration (users, stats, verifications)
│   ├── notifications.js # Tokens FCM, envoi, gestion
│   ├── aiChat.js        # Conversations IA
│   ├── aiFeatures.js    # Predictions, suggestions
│   ├── webhooks.js      # Webhooks Stripe
│   └── ...              # vehicles, support, messages, parking-spots, phone
├── services/            # 12 services metier
│   ├── smartMatchingService.js       # Matching deneigeur-reservation (score)
│   ├── demandPredictionService.js    # Prediction de demande par zone
│   ├── disputeAnalysisService.js     # Analyse IA des litiges
│   ├── smartNotificationService.js   # Notifications contextuelles (ETA, meteo)
│   ├── photoAnalysisService.js       # Analyse IA des photos avant/apres
│   ├── identityVerificationService.js # Verification pieces d'identite
│   ├── firebaseService.js            # Push notifications FCM
│   ├── claudeService.js              # Integration Claude (Anthropic)
│   ├── twilioService.js              # SMS via Twilio
│   └── ...                           # cleanup, expired jobs, logger
└── server.js            # Point d'entree (Express, Socket.IO, cron)
```

## Roles utilisateurs

| Role | Description |
|------|-------------|
| **Client** | Reserve un deneigement, paie via Stripe, note le deneigeur |
| **Deneigeur** | Consulte les jobs disponibles, accepte, execute, recoit le paiement |
| **Admin** | Gere les utilisateurs, verifications d'identite, litiges, statistiques |

## Flux de reservation

1. Le client selectionne son vehicule et sa place de stationnement
2. Il choisit la date, l'heure de depart et les options de service
3. Il revise le recapitulatif (prix + taxes QC) et confirme
4. Le systeme assigne automatiquement le meilleur deneigeur (score: distance, note, equipement)
5. Le deneigeur recoit une notification, accepte et se rend sur place
6. Photos avant/apres, completion, paiement automatique via Stripe Connect

## Tarification

- Prix de base : 15,00 $ CAD
- Par cm de neige : 0,50 $ / cm
- Options : grattage vitres (8 $), deglacage portes (3 $), degagement roues (4 $), etc.
- Supplement urgence : +40 % si < 45 min avant le depart
- Taxes : TPS 5 % + TVQ 9,975 % (Quebec)
- Abonnements : hebdomadaire (39 $), mensuel (129 $), saisonnier (399 $)

## Variables d'environnement

Copier `.env.example` dans `backend/.env` et configurer :

| Variable | Description |
|----------|-------------|
| `MONGODB_URI` | URI de connexion MongoDB |
| `JWT_SECRET` | Secret pour les tokens JWT |
| `STRIPE_SECRET_KEY` | Cle secrete Stripe |
| `FIREBASE_*` | Configuration Firebase Admin |
| `TWILIO_*` | Configuration Twilio (SMS) |
| `ANTHROPIC_API_KEY` | Cle API Claude (IA) |
| `CLOUDINARY_*` | Configuration Cloudinary (images) |
| `OPENWEATHER_API_KEY` | Cle OpenWeatherMap |

Voir `.env.example` et `.env.production.example` pour la liste complete.

## Commandes utiles

```bash
# Flutter
flutter pub get                 # Installer les dependances
flutter run                     # Lancer en mode dev
flutter test                    # Lancer les tests
flutter analyze                 # Verifier le code
flutter build apk --release     # Build Android
flutter build ios --release     # Build iOS

# Backend
cd backend
npm install                     # Installer les dependances
npm run dev                     # Dev avec hot reload
npm start                       # Production
npm test                        # Tests Jest
```

## Tests

### Flutter (58 fichiers de test)

```
test/
├── features/
│   ├── auth/           # Tests BLoC, datasource, repository, usecases
│   ├── payment/        # Tests BLoC et usecases paiement
│   ├── reservation/    # Tests BLoC, datasource, repository
│   ├── notifications/  # Tests BLoC notifications
│   ├── snow_worker/    # Tests BLoC deneigeur
│   └── vehicule/       # Tests BLoC vehicules
├── fixtures/           # Donnees de test (user, payment, worker, etc.)
└── helpers/            # Mocks et utilitaires de test
```

### Backend

Tests via Jest + Supertest + mongodb-memory-server.

## Feature flags

Configurables dans `lib/core/config/app_config.dart` :

| Flag | Statut | Description |
|------|--------|-------------|
| `enableWeatherAPI` | Actif | Integration meteo |
| `enableChatFeature` | V2 | Messagerie in-app |
| `enableFamilySharing` | V2 | Partage de compte familial |
| `enableMultiBuilding` | V2 | Support multi-immeubles |
