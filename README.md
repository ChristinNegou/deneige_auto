

## Project Overview

**Dénéige-Auto** is a community snow removal application for apartment buildings, connecting residents who need their vehicles cleared with snow removal workers. The system consists of:

- **Flutter mobile app** (primary client) - iOS & Android support
- **Node.js/Express backend API** - MongoDB database
- Two user roles: **Clients** (residents) and **Snow Workers** (déneigeurs)

## Development Commands

### Flutter (Mobile App)

```bash
# Install dependencies
flutter pub get

# Run code generation (models, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app in development mode
flutter run

# Run on specific device
flutter run -d <device-id>

# Run tests
flutter test

# Run a specific test
flutter test test/widget_test.dart

# Build for production
flutter build apk --release           # Android
flutter build ios --release           # iOS

# Lint code
flutter analyze
```

### Backend API

```bash
cd backend

# Install dependencies
npm install

# Start development server with hot reload
npm run dev

# Start production server
npm start

# Verbose development mode
npm run dev:verbose
```

The backend runs on port 3000 by default (configurable via `PORT` environment variable).

## Architecture

### Flutter App Architecture

The app follows **Clean Architecture** with **BLoC** state management:

```
lib/
├── core/
│   ├── config/          # App configuration (API URLs, keys, business rules)
│   ├── di/              # Dependency injection (GetIt service locator)
│   ├── network/         # Dio HTTP client configuration
│   ├── routing/         # App navigation (AppRouter with named routes)
│   ├── services/        # Cross-cutting services (LocationService, SecureStorage)
│   └── errors/          # Error handling (Failures with dartz Either)
│
├── features/            # Feature modules (one per business domain)
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/    # Remote data sources (API calls)
│       │   ├── models/         # Data models with JSON serialization
│       │   └── repositories/   # Repository implementations
│       ├── domain/
│       │   ├── entities/       # Business entities (pure Dart classes)
│       │   ├── repositories/   # Repository interfaces
│       │   └── usecases/       # Business logic use cases
│       └── presentation/
│           ├── bloc/           # BLoC state management
│           ├── pages/          # Full-screen pages
│           ├── screens/        # Routable screens
│           └── widgets/        # Reusable UI components
```

### Key Features

- **auth** - Authentication (login, register, password reset, profile updates)
- **home** - Dashboard with weather and upcoming reservations
- **reservation** - Create/view reservations (multi-step process)
- **vehicule** - Vehicle management
- **weather** - Weather forecasting (OpenWeatherMap integration)
- **profile** - User profile and settings
- **snow_worker** - Snow worker dashboard and job management
- **dashboard** - Analytics and overview
- **subscription** - Subscription management (weekly/monthly/seasonal)

### Dependency Injection

All dependencies are registered in `lib/core/di/injection_container.dart` using GetIt:

```dart
final sl = GetIt.instance;

// Access dependencies anywhere:
sl<AuthBloc>()
sl<DioClient>()
sl<WeatherRepository>()
```

Registration order:
1. Core services (SecureStorage, DioClient, SharedPreferences)
2. Data sources
3. Repositories
4. Use cases
5. BLoCs (registered as factories for fresh instances)

### State Management

Uses **flutter_bloc** pattern:
- Events (`*_event.dart`) - User actions
- States (`*_state.dart`) - UI states (Initial, Loading, Success, Error)
- BLoCs (`*_bloc.dart`) - Business logic processors

Example BLoC instantiation:
```dart
BlocProvider(
  create: (context) => sl<NewReservationBloc>(
    getVehicles: sl(),
    getParkingSpots: sl(),
    createReservation: sl(),
  ),
  child: const NewReservationScreen(),
)
```

### Navigation

Centralized routing in `lib/core/routing/app_router.dart`:
- Named routes defined in `AppRoutes` constants
- Automatic BLoC provider wrapping in route generation
- Role-based home page routing via `RoleBasedHomeWrapper`

Navigate using:
```dart
AppRouter.navigateTo(context, AppRoutes.newReservation);
AppRouter.navigateToAndClearStack(context, AppRoutes.login);
```

### Error Handling

Uses **dartz** `Either<Failure, Success>` pattern:
- Left: Failure (ServerFailure, NetworkFailure, ValidationFailure)
- Right: Success data

All use cases return `Future<Either<Failure, T>>`.

### API Integration

Backend API base URL configured in `lib/core/config/app_config.dart`:
- Development: `http://localhost:3000/v1`
- Staging: `https://staging-api.deneige-auto.com/v1`
- Production: `https://api.deneige-auto.com/v1`

API client uses Dio with:
- JWT token authentication (stored in flutter_secure_storage)
- Automatic token injection via interceptors
- Request/response logging in debug mode

### Backend API Structure

```
backend/
├── config/          # Database connection
├── middleware/      # Auth middleware, validation
├── models/          # MongoDB schemas (User, Reservation, Vehicle, ParkingSpot)
├── routes/          # Express route handlers
│   ├── auth.js
│   ├── reservations.js
│   ├── vehicles.js
│   └── parking-spots.js
└── server.js        # Main entry point
```

API endpoints:
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/forgot-password` - Request password reset
- `PUT /api/auth/reset-password/:token` - Reset password with token
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/update-profile` - Update user profile
- `GET /api/reservations` - List reservations
- `POST /api/reservations` - Create reservation
- `GET /api/reservations/:id` - Get reservation details
- `DELETE /api/reservations/:id` - Cancel reservation
- `GET /api/vehicles` - List user vehicles
- `POST /api/vehicles` - Add vehicle
- `GET /api/parking-spots` - List available parking spots

### Environment Configuration

**Backend**: Create `.env` file in `backend/` directory:
```
MONGODB_URI=mongodb://...
JWT_SECRET=your_secret_key
PORT=3000
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:3000,http://10.0.2.2:3000
EMAIL_SERVICE=gmail
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password
```

**Flutter**: API keys are in `lib/core/config/app_config.dart`:
- OpenWeatherMap API key (current: `ab72e143d388c56b44d4571dd67697ba`)
- Google Maps API key (current: `AIzaSyBYGaWXAeRC5ScUL8bM3emRobMMlVQ05VE`)
- Stripe keys (test mode keys present)

**IMPORTANT**: Replace hardcoded API keys with environment-specific values for production.

### Business Rules (in AppConfig)

- Minimum reservation time: 60 minutes before departure
- Urgency fee: +40% if booking < 45 minutes
- Base price: $15.00 CAD
- Price per cm of snow: $0.50 CAD
- Service surcharges: Ice removal ($5), Door deicing ($3), Wheel clearance ($4)
- Subscription pricing: Weekly ($39), Monthly ($129), Seasonal ($399)
- Max simultaneous jobs per worker: 3
- Late tolerance: 15 minutes

### Database Models (MongoDB)

Key collections:
- **users** - Authentication and profile (role: client/worker/admin)
- **vehicles** - User vehicles (make, model, licensePlate, parkingSpot)
- **reservations** - Booking records (user, vehicle, dateTime, services, price, status)
- **parkingSpots** - Available parking locations

### Multi-Step Reservation Flow

The reservation creation uses a 4-step wizard in `NewReservationScreen`:
1. **Step 1**: Select vehicle and parking spot
2. **Step 2**: Choose date and time
3. **Step 3**: Add service options (ice removal, door deicing, etc.)
4. **Step 4**: Review summary and confirm

State managed by `NewReservationBloc` with cumulative form data.

## Code Generation

When modifying models with JSON serialization:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates `*.g.dart` files for:
- JSON serialization (`json_serializable`)
- Retrofit API clients
- Hive type adapters

## Testing on Android Emulator

Backend URL for Android emulator:
- Use `http://10.0.2.2:3000` instead of `localhost:3000`

## Location Services

The app uses `geolocator` for user location and `geocoding` for address lookup. Location permissions required:
- iOS: Update `Info.plist` with location usage descriptions
- Android: Permissions already in `AndroidManifest.xml`

Default location: Trois-Rivières, QC (46.3432, -72.5476)

## Common Gotchas

1. **Missing code generation**: If JSON models fail, run build_runner
2. **BLoC not accessible**: Ensure BLoC is provided in widget tree before accessing
3. **API connection failed**: Check backend is running and API base URL matches environment
4. **Token expired**: JWT tokens are stored securely; logout/login refreshes tokens
5. **Null safety**: Project uses sound null safety (SDK >=3.0.0)

## Feature Flags

Controlled in `AppConfig`:
- `enableWeatherAPI` - Weather integration (enabled)
- `enableChatFeature` - In-app chat (V2, disabled)
- `enableFamilySharing` - Share accounts (V2, disabled)
- `enableMultiBuilding` - Multiple buildings (V2, disabled)

## Role-Based Access

User roles determine app experience:
- **client**: Home screen with reservation features
- **worker**: Snow worker dashboard with job list
- **admin**: Administrative features

Navigation automatically routes to role-appropriate home screen via `RoleBasedHomeWrapper`.
