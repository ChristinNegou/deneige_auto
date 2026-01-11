/// Main barrel export file for the core module
/// Import this file to access all core functionality at once:
/// `import 'package:deneige_auto/core/core.dart';`
///
/// For more granular imports, use the individual barrel files:
/// - `import 'package:deneige_auto/core/services/services.dart';`
/// - `import 'package:deneige_auto/core/utils/utils.dart';`
/// - `import 'package:deneige_auto/core/cache/cache.dart';`
/// - `import 'package:deneige_auto/core/config/config.dart';`
/// - `import 'package:deneige_auto/core/constants/constants.dart';`
/// - `import 'package:deneige_auto/core/errors/errors.dart';`
/// - `import 'package:deneige_auto/core/widgets/widgets.dart';`
library;

// Cache (Hive-based generic cache)
export 'cache/cache.dart';

// Config
export 'config/config.dart';

// Constants
export 'constants/constants.dart';

// Dependency Injection
export 'di/injection_container.dart';

// Errors
export 'errors/errors.dart';

// Network
export 'network/dio_client.dart';

// Routing
export 'routing/app_router.dart';
export 'routing/role_based_home_wrapper.dart';

// Services
export 'services/services.dart';

// Theme
export 'theme/app_theme.dart';

// Utils
export 'utils/utils.dart';

// Widgets
export 'widgets/widgets.dart';
