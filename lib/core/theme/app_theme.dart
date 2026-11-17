import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme "Hivernal & net" de l'application Deneige Auto.
/// Fond bleu-glace, encre bleu nuit pour le texte et les actions courantes,
/// orange signalisation reserve aux actions cles (reserver, payer, demarrer).
///
/// Les noms des tokens sont conserves depuis l'ancien theme sombre afin que
/// tous les ecrans existants basculent sur la nouvelle palette sans changement.
class AppTheme {
  AppTheme._();

  // --- Couleurs principales ---

  /// Fond principal - Bleu glace
  static const Color background = Color(0xFFF3F6F9);

  /// Fond des cartes - Blanc
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface élevée - Pour les cartes au-dessus (feuilles, dialogues)
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  /// Surface container - Pour les inputs et éléments interactifs
  static const Color surfaceContainer = Color(0xFFE9EEF3);

  /// Fond des cartes avec transparence
  static const Color surfaceGlass = Color(0xF2FFFFFF); // 95% opacity

  /// Texte principal - Bleu nuit
  static const Color textPrimary = Color(0xFF0E1C2B);

  /// Texte secondaire - Ardoise
  static const Color textSecondary = Color(0xFF4A5A6B);

  /// Texte tertiaire - Ardoise claire
  static const Color textTertiary = Color(0xFF7D8A98);

  /// Texte désactivé
  static const Color textDisabled = Color(0xFFB3BDC7);

  /// Encre principale - Bleu nuit (boutons, icones actives, liens)
  static const Color primary = Color(0xFF0E1C2B);

  /// Bleu glacier - accent informatif secondaire
  static const Color primary2 = Color(0xFF2F6FB0);
  static const Color primary3 = Color(0xFF8FB8DE);

  /// Encre principale atténuée (fonds selectionnes)
  static const Color primaryLight = Color(0xFFE3EAF2);

  /// Accent secondaire - Ardoise
  static const Color secondary = Color(0xFF4A5A6B);

  /// Orange signalisation - reserve aux actions cles, a utiliser avec parcimonie
  static const Color accent = Color(0xFFF26B1D);
  static const Color accentDark = Color(0xFFC9520F);
  static const Color accentLight = Color(0xFFFDEBDF);

  /// Texte sur fond primary / accent
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Couleur succès - Vert sapin
  static const Color success = Color(0xFF1F9D63);
  static const Color successLight = Color(0xFFE3F5EC);

  /// Couleur warning - Ambre
  static const Color warning = Color(0xFFC98A06);
  static const Color warningLight = Color(0xFFFBF1D9);

  /// Couleur erreur - Rouge
  static const Color error = Color(0xFFD64545);
  static const Color errorLight = Color(0xFFFBE6E6);

  /// Couleur info - Bleu glacier
  static const Color info = Color(0xFF2F6FB0);
  static const Color infoLight = Color(0xFFE2EDF8);

  /// Bordures et séparateurs
  static const Color border = Color(0xFFDCE3EA);
  static const Color divider = Color(0xFFE8EDF2);

  /// Couleur d'ombre - teintee bleu nuit pour des ombres naturelles
  static const Color shadowColor = Color(0xFF0E1C2B);

  // --- Couleurs de statut de reservation ---

  static const Color statusPending = Color(0xFFC98A06);
  static const Color statusPendingBg = Color(0xFFFBF1D9);

  static const Color statusAssigned = Color(0xFF2F6FB0);
  static const Color statusAssignedBg = Color(0xFFE2EDF8);

  static const Color statusEnRoute = Color(0xFF0E8A9A);
  static const Color statusEnRouteBg = Color(0xFFDFF3F5);

  static const Color statusInProgress = Color(0xFFF26B1D);
  static const Color statusInProgressBg = Color(0xFFFDEBDF);

  static const Color statusCompleted = Color(0xFF1F9D63);
  static const Color statusCompletedBg = Color(0xFFE3F5EC);

  static const Color statusCancelled = Color(0xFF7D8A98);
  static const Color statusCancelledBg = Color(0xFFEDF1F5);

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
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.6,
    height: 1.2,
  );

  /// Titre de section
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  /// Titre de carte
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.1,
  );

  /// Corps de texte
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );

  /// Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textTertiary,
  );

  static TextTheme get _textTheme => GoogleFonts.manropeTextTheme(
        const TextTheme(
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

  /// Configuration complete du ThemeData Material 3 en mode clair.
  static ThemeData get lightTheme {
    final textTheme = _textTheme;
    final buttonText = textTheme.labelLarge!.copyWith(fontSize: 16);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.manrope().fontFamily,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
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
          side: const BorderSide(color: border, width: 1.5),
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
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
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error, width: 1.5),
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
      dividerTheme: const DividerThemeData(
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
          side: const BorderSide(color: border),
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
      bottomSheetTheme: const BottomSheetThemeData(
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
      progressIndicatorTheme: const ProgressIndicatorThemeData(
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
        side: const BorderSide(color: textTertiary, width: 1.5),
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

  /// Alias pour la compatibilité (l'application n'a plus de theme sombre)
  static ThemeData get darkTheme => lightTheme;
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
