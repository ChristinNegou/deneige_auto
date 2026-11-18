import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Les couleurs du theme "Hivernal & net", en version claire et sombre.
class AppPalette {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceContainer;
  final Color surfaceGlass;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color primary;
  final Color primary2;
  final Color primary3;
  final Color primaryLight;
  final Color secondary;
  final Color accent;
  final Color accentDark;
  final Color accentLight;
  final Color onPrimary;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;
  final Color border;
  final Color divider;
  final Color shadowColor;
  final Color statusPending;
  final Color statusPendingBg;
  final Color statusAssigned;
  final Color statusAssignedBg;
  final Color statusEnRoute;
  final Color statusEnRouteBg;
  final Color statusInProgress;
  final Color statusInProgressBg;
  final Color statusCompleted;
  final Color statusCompletedBg;
  final Color statusCancelled;
  final Color statusCancelledBg;

  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceContainer,
    required this.surfaceGlass,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.primary,
    required this.primary2,
    required this.primary3,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.onPrimary,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.border,
    required this.divider,
    required this.shadowColor,
    required this.statusPending,
    required this.statusPendingBg,
    required this.statusAssigned,
    required this.statusAssignedBg,
    required this.statusEnRoute,
    required this.statusEnRouteBg,
    required this.statusInProgress,
    required this.statusInProgressBg,
    required this.statusCompleted,
    required this.statusCompletedBg,
    required this.statusCancelled,
    required this.statusCancelledBg,
  });

  /// Fond bleu-glace, encre bleu nuit, orange signalisation.
  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF3F6F9),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFE9EEF3),
    surfaceGlass: Color(0xF2FFFFFF),
    textPrimary: Color(0xFF0E1C2B),
    textSecondary: Color(0xFF4A5A6B),
    textTertiary: Color(0xFF7D8A98),
    textDisabled: Color(0xFFB3BDC7),
    primary: Color(0xFF0E1C2B),
    primary2: Color(0xFF2F6FB0),
    primary3: Color(0xFF8FB8DE),
    primaryLight: Color(0xFFE3EAF2),
    secondary: Color(0xFF4A5A6B),
    accent: Color(0xFFF26B1D),
    accentDark: Color(0xFFC9520F),
    accentLight: Color(0xFFFDEBDF),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF1F9D63),
    successLight: Color(0xFFE3F5EC),
    warning: Color(0xFFC98A06),
    warningLight: Color(0xFFFBF1D9),
    error: Color(0xFFD64545),
    errorLight: Color(0xFFFBE6E6),
    info: Color(0xFF2F6FB0),
    infoLight: Color(0xFFE2EDF8),
    border: Color(0xFFDCE3EA),
    divider: Color(0xFFE8EDF2),
    shadowColor: Color(0xFF0E1C2B),
    statusPending: Color(0xFFC98A06),
    statusPendingBg: Color(0xFFFBF1D9),
    statusAssigned: Color(0xFF2F6FB0),
    statusAssignedBg: Color(0xFFE2EDF8),
    statusEnRoute: Color(0xFF0E8A9A),
    statusEnRouteBg: Color(0xFFDFF3F5),
    statusInProgress: Color(0xFFF26B1D),
    statusInProgressBg: Color(0xFFFDEBDF),
    statusCompleted: Color(0xFF1F9D63),
    statusCompletedBg: Color(0xFFE3F5EC),
    statusCancelled: Color(0xFF7D8A98),
    statusCancelledBg: Color(0xFFEDF1F5),
  );

  /// Nuit d'hiver : fond bleu nuit profond, texte glace. L'encre principale
  /// devient bleu glace pale (texte bleu nuit dessus) pour rester lisible
  /// comme texte sur le fond et comme fond de bouton ou de panneau.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0C1724),
    surface: Color(0xFF142231),
    surfaceElevated: Color(0xFF1A2B3D),
    surfaceContainer: Color(0xFF1F3144),
    surfaceGlass: Color(0xF2142231),
    textPrimary: Color(0xFFE8EEF4),
    textSecondary: Color(0xFFA9B7C5),
    textTertiary: Color(0xFF7F8E9D),
    textDisabled: Color(0xFF4C5B6B),
    primary: Color(0xFFDCE6F0),
    primary2: Color(0xFF6AA7E6),
    primary3: Color(0xFF3E6F9E),
    primaryLight: Color(0xFF1E3247),
    secondary: Color(0xFFA9B7C5),
    accent: Color(0xFFF57A30),
    accentDark: Color(0xFFFF9F66),
    accentLight: Color(0xFF3A2416),
    onPrimary: Color(0xFF0E1C2B),
    success: Color(0xFF3CC384),
    successLight: Color(0xFF123526),
    warning: Color(0xFFE3A92B),
    warningLight: Color(0xFF382B0E),
    error: Color(0xFFF06A6A),
    errorLight: Color(0xFF3D1A1D),
    info: Color(0xFF6AA7E6),
    infoLight: Color(0xFF162D45),
    border: Color(0xFF2A3D51),
    divider: Color(0xFF22344A),
    shadowColor: Color(0xFF000000),
    statusPending: Color(0xFFE3A92B),
    statusPendingBg: Color(0xFF382B0E),
    statusAssigned: Color(0xFF6AA7E6),
    statusAssignedBg: Color(0xFF162D45),
    statusEnRoute: Color(0xFF3FC0D0),
    statusEnRouteBg: Color(0xFF0F3239),
    statusInProgress: Color(0xFFF57A30),
    statusInProgressBg: Color(0xFF3A2416),
    statusCompleted: Color(0xFF3CC384),
    statusCompletedBg: Color(0xFF123526),
    statusCancelled: Color(0xFF8A98A7),
    statusCancelledBg: Color(0xFF1E2B39),
  );
}

/// Theme "Hivernal & net" de l'application Deneige Auto.
/// Fond bleu-glace, encre bleu nuit pour le texte et les actions courantes,
/// orange signalisation reserve aux actions cles (reserver, payer, demarrer).
///
/// Les couleurs suivent la palette active (claire ou sombre) : changer de
/// palette avec [usePalette] puis reconstruire l'app suffit a tout basculer.
class AppTheme {
  AppTheme._();

  static AppPalette _palette = AppPalette.light;

  /// Palette active.
  static AppPalette get palette => _palette;

  static bool get isDark => _palette.brightness == Brightness.dark;

  /// Change la palette. L'app doit ensuite se reconstruire en entier.
  static void usePalette(AppPalette palette) => _palette = palette;

  // --- Couleurs principales ---

  /// Fond principal - Bleu glace
  static Color get background => _palette.background;

  /// Fond des cartes - Blanc
  static Color get surface => _palette.surface;

  /// Surface élevée - Pour les cartes au-dessus (feuilles, dialogues)
  static Color get surfaceElevated => _palette.surfaceElevated;

  /// Surface container - Pour les inputs et éléments interactifs
  static Color get surfaceContainer => _palette.surfaceContainer;

  /// Fond des cartes avec transparence
  static Color get surfaceGlass => _palette.surfaceGlass;

  /// Texte principal - Bleu nuit
  static Color get textPrimary => _palette.textPrimary;

  /// Texte secondaire - Ardoise
  static Color get textSecondary => _palette.textSecondary;

  /// Texte tertiaire - Ardoise claire
  static Color get textTertiary => _palette.textTertiary;

  /// Texte désactivé
  static Color get textDisabled => _palette.textDisabled;

  /// Encre principale - Bleu nuit (boutons, icones actives, liens)
  static Color get primary => _palette.primary;

  /// Bleu glacier - accent informatif secondaire
  static Color get primary2 => _palette.primary2;
  static Color get primary3 => _palette.primary3;

  /// Encre principale atténuée (fonds selectionnes)
  static Color get primaryLight => _palette.primaryLight;

  /// Accent secondaire - Ardoise
  static Color get secondary => _palette.secondary;

  /// Orange signalisation - reserve aux actions cles, a utiliser avec parcimonie
  static Color get accent => _palette.accent;
  static Color get accentDark => _palette.accentDark;
  static Color get accentLight => _palette.accentLight;

  /// Texte sur fond primary / accent
  static Color get onPrimary => _palette.onPrimary;

  /// Couleur succès - Vert sapin
  static Color get success => _palette.success;
  static Color get successLight => _palette.successLight;

  /// Couleur warning - Ambre
  static Color get warning => _palette.warning;
  static Color get warningLight => _palette.warningLight;

  /// Couleur erreur - Rouge
  static Color get error => _palette.error;
  static Color get errorLight => _palette.errorLight;

  /// Couleur info - Bleu glacier
  static Color get info => _palette.info;
  static Color get infoLight => _palette.infoLight;

  /// Bordures et séparateurs
  static Color get border => _palette.border;
  static Color get divider => _palette.divider;

  /// Couleur d'ombre - teintee bleu nuit pour des ombres naturelles
  static Color get shadowColor => _palette.shadowColor;

  // --- Couleurs de statut de reservation ---

  static Color get statusPending => _palette.statusPending;
  static Color get statusPendingBg => _palette.statusPendingBg;

  static Color get statusAssigned => _palette.statusAssigned;
  static Color get statusAssignedBg => _palette.statusAssignedBg;

  static Color get statusEnRoute => _palette.statusEnRoute;
  static Color get statusEnRouteBg => _palette.statusEnRouteBg;

  static Color get statusInProgress => _palette.statusInProgress;
  static Color get statusInProgressBg => _palette.statusInProgressBg;

  static Color get statusCompleted => _palette.statusCompleted;
  static Color get statusCompletedBg => _palette.statusCompletedBg;

  static Color get statusCancelled => _palette.statusCancelled;
  static Color get statusCancelledBg => _palette.statusCancelledBg;

  // --- Dimensions et espacements (grille de 4dp) ---

  /// Padding standard
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 12.0;
  static const double paddingLG = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;

  /// Border radius - plus petit sur les petits elements, plus grand sur les feuilles
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  /// Hauteurs
  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;
  static const double headerHeight = 100.0;
  static const double bottomNavHeight = 68.0;

  /// Ombres douces teintees bleu nuit, adaptees au fond clair
  static List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMD => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get shadowLG => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  /// Halo discret pour l'action cle (orange)
  static List<BoxShadow> get glowPrimary => [
        BoxShadow(
          color: accent.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// Effet de surélévation pour les cartes actives
  static List<BoxShadow> get shadowElevated => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  // --- Decorations de cartes et conteneurs ---

  /// Décoration carte translucide
  static BoxDecoration get glassCard => BoxDecoration(
        color: surfaceGlass,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: border),
        boxShadow: shadowSM,
      );

  /// Décoration carte standard
  static BoxDecoration get card => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: border.withValues(alpha: 0.6)),
        boxShadow: shadowSM,
      );

  /// Décoration carte élevée
  static BoxDecoration get cardElevated => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusLG),
        boxShadow: shadowMD,
      );

  /// Décoration carte avec bordure subtile
  static BoxDecoration get cardBordered => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: border),
      );

  /// Décoration pour les inputs
  static BoxDecoration get inputDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusMD),
        border: Border.all(color: border),
      );

  /// Décoration pour les éléments interactifs selectionnes
  static BoxDecoration get cardActive => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: primary, width: 1.5),
        boxShadow: shadowMD,
      );

  // --- Styles de texte (Manrope, applique via le ThemeData) ---

  /// Titre principal (page)
  static TextStyle get headlineLarge => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.6,
        height: 1.2,
      );

  /// Titre de section
  static TextStyle get headlineMedium => TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
        height: 1.25,
      );

  /// Titre de carte
  static TextStyle get headlineSmall => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.1,
      );

  /// Corps de texte
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.45,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.45,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.4,
      );

  /// Labels
  static TextStyle get labelLarge => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get labelMedium => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textTertiary,
      );

  static TextTheme get _textTheme => GoogleFonts.manropeTextTheme(
        TextTheme(
          displaySmall: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: textPrimary,
          ),
          headlineLarge: headlineLarge,
          headlineMedium: headlineMedium,
          headlineSmall: headlineSmall,
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          bodyLarge: bodyLarge,
          bodyMedium: bodyMedium,
          bodySmall: bodySmall,
          labelLarge: labelLarge,
          labelMedium: labelMedium,
          labelSmall: labelSmall,
        ),
      );

  // --- ThemeData Material 3 ---

  /// ThemeData Material 3 de la palette active.
  static ThemeData get theme {
    final textTheme = _textTheme;
    final buttonText = textTheme.labelLarge!.copyWith(fontSize: 16);

    return ThemeData(
      useMaterial3: true,
      brightness: _palette.brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.manrope().fontFamily,
      textTheme: textTheme,
      colorScheme: ColorScheme(
        brightness: _palette.brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: primary,
        secondary: accent,
        onSecondary: onPrimary,
        secondaryContainer: accentLight,
        onSecondaryContainer: accentDark,
        tertiary: primary2,
        onTertiary: onPrimary,
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceContainerHighest: surfaceContainer,
        outline: border,
        outlineVariant: divider,
        error: error,
        onError: onPrimary,
        shadow: shadowColor,
      ),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        systemOverlayStyle: systemOverlayStyle,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: BorderSide(color: border.withValues(alpha: 0.6)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceContainer,
          disabledForegroundColor: textDisabled,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceContainer,
          disabledForegroundColor: textDisabled,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          backgroundColor: surface,
          minimumSize: const Size(double.infinity, buttonHeight),
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary2,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onPrimary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
        hintStyle: textTheme.bodyMedium!.copyWith(color: textTertiary),
        labelStyle: textTheme.bodyMedium!.copyWith(color: textSecondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        selectedLabelStyle:
            textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryLight,
        height: bottomNavHeight,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textTertiary,
        indicatorColor: primary,
        dividerColor: divider,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle:
            textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryLight,
        labelStyle: labelMedium.copyWith(color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: onPrimary),
        actionTextColor: accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return onPrimary;
          }
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return success;
          }
          return surfaceContainer;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return border;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: textTertiary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return textTertiary;
        }),
      ),
    );
  }

  /// Icones de la barre d'etat lisibles sur le fond de la palette active.
  static SystemUiOverlayStyle get systemOverlayStyle => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      );
}

/// Carte de contenu principale : fond blanc, bordure fine et ombre douce.
/// Le nom est conserve pour la compatibilite avec les ecrans existants.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = AppTheme.radiusLG,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: AppTheme.border.withValues(alpha: elevated ? 0.3 : 0.7),
        ),
        boxShadow: elevated ? AppTheme.shadowMD : AppTheme.shadowSM,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.paddingLG),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Badge de statut compact avec couleur de fond teintee.
/// Utilise pour afficher les statuts de reservation, jobs, etc.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? color.withValues(alpha: 0.12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton d'action compact avec icone et label.
/// Supporte les variantes pleine et contouree (outlined).
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool outlined;
  final bool small;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.outlined = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primary;
    final textColor = outlined ? buttonColor : AppTheme.onPrimary;

    return Material(
      color: outlined ? AppTheme.surface : buttonColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        splashColor: buttonColor.withValues(alpha: 0.1),
        highlightColor: buttonColor.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 16,
            vertical: small ? 8 : 11,
          ),
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.border, width: 1.5),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: small ? 16 : 18,
                color: textColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
