import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme sombre premium de l'application Deneige Auto.
/// Palette de couleurs, typographie, decorations et composants UI reutilisables
/// inspires du design Uber avec un mode sombre confortable pour les yeux.
class AppTheme {
  AppTheme._();

  // --- Couleurs principales ---

  /// Fond principal - Noir profond chaleureux (pas noir pur)
  static const Color background = Color(0xFF0A0A0A);

  /// Fond des cartes - Gris anthracite doux
  static const Color surface = Color(0xFF161616);

  /// Surface élevée - Pour les cartes au-dessus
  static const Color surfaceElevated = Color(0xFF1E1E1E);

  /// Surface container - Pour les inputs et éléments interactifs
  static const Color surfaceContainer = Color(0xFF252525);

  /// Fond des cartes avec transparence (glassmorphism)
  static const Color surfaceGlass = Color(0xE6161616); // 90% opacity

  /// Texte principal - Blanc cassé (plus doux pour les yeux)
  static const Color textPrimary = Color(0xFFF5F5F5);

  /// Texte secondaire - Gris clair
  static const Color textSecondary = Color(0xFFB3B3B3);

  /// Texte tertiaire - Gris moyen
  static const Color textTertiary = Color(0xFF787878);

  /// Texte désactivé
  static const Color textDisabled = Color(0xFF505050);

  /// Accent principal - Blanc pur (style Uber)
  static const Color primary = Color(0xFFFFFFFF);

  /// Accent principal variantes
  static const Color primary2 = Color(0xFF7E57C2);
  static const Color primary3 = Color(0xFFCE93D8);

  /// Accent principal atténué
  static const Color primaryLight = Color(0xFF2A2A2A);

  /// Accent secondaire - Gris clair
  static const Color secondary = Color(0xFFE0E0E0);

  /// Couleur succès - Vert Uber
  static const Color success = Color(0xFF34D399);
  static const Color successLight = Color(0xFF162D22);

  /// Couleur warning - Jaune doux
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFF2D2612);

  /// Couleur erreur - Rouge doux
  static const Color error = Color(0xFFF87171);
  static const Color errorLight = Color(0xFF2D1616);

  /// Couleur info - Bleu ciel
  static const Color info = Color(0xFF60A5FA);
  static const Color infoLight = Color(0xFF162339);

  /// Bordures et séparateurs
  static const Color border = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF1F1F1F);

  /// Couleur d'ombre
  static const Color shadowColor = Color(0xFF000000);

  // --- Couleurs de statut de reservation ---

  static const Color statusPending = Color(0xFFFBBF24);
  static const Color statusPendingBg = Color(0xFF2D2612);

  static const Color statusAssigned = Color(0xFF60A5FA);
  static const Color statusAssignedBg = Color(0xFF162339);

  static const Color statusEnRoute = Color(0xFFA78BFA);
  static const Color statusEnRouteBg = Color(0xFF221B33);

  static const Color statusInProgress = Color(0xFF34D399);
  static const Color statusInProgressBg = Color(0xFF162D22);

  static const Color statusCompleted = Color(0xFF10B981);
  static const Color statusCompletedBg = Color(0xFF122D23);

  static const Color statusCancelled = Color(0xFF9CA3AF);
  static const Color statusCancelledBg = Color(0xFF1F2125);

  // --- Dimensions et espacements ---

  /// Padding standard
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 12.0;
  static const double paddingLG = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;

  /// Border radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusFull = 100.0;

  /// Hauteurs
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
  static const double headerHeight = 100.0;
  static const double bottomNavHeight = 64.0;

  /// Ombres optimisées pour le mode sombre
  /// En dark mode, on utilise des ombres plus subtiles avec luminosité réduite
  static List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMD => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLG => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Effet de glow subtil pour les éléments importants
  static List<BoxShadow> get glowPrimary => [
        BoxShadow(
          color: primary.withValues(alpha: 0.15),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  /// Effet de surélévation pour les cartes actives
  static List<BoxShadow> get shadowElevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  // --- Decorations de cartes et conteneurs ---

  /// Décoration carte glassmorphism
  static BoxDecoration get glassCard => BoxDecoration(
        color: surfaceGlass,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: border.withValues(alpha: 0.3)),
        boxShadow: shadowMD,
      );

  /// Décoration carte standard
  static BoxDecoration get card => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusLG),
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
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(radiusMD),
        border: Border.all(color: border),
      );

  /// Décoration pour les éléments interactifs au survol/focus
  static BoxDecoration get cardActive => BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusLG),
        border: Border.all(color: textTertiary.withValues(alpha: 0.3)),
        boxShadow: shadowMD,
      );

  // --- Styles de texte ---

  /// Titre principal (page)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  /// Titre de section
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  /// Titre de carte
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Corps de texte
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  /// Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textTertiary,
  );

  // --- ThemeData Material 3 ---

  /// Configuration complete du ThemeData Material 3 en mode sombre.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: background,
          onSecondary: background,
          onSurface: textPrimary,
          onError: background,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primary,
            foregroundColor: background,
            minimumSize: const Size(double.infinity, buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMD),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            minimumSize: const Size(double.infinity, buttonHeight),
            side: const BorderSide(color: border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMD),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: textPrimary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceContainer,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            borderSide: const BorderSide(color: textSecondary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMD),
            borderSide: const BorderSide(color: error),
          ),
          hintStyle: const TextStyle(color: textTertiary),
          labelStyle: const TextStyle(color: textSecondary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: textPrimary,
          unselectedItemColor: textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceContainer,
          selectedColor: surfaceElevated,
          labelStyle: labelMedium,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
            side: const BorderSide(color: border),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          modalBackgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceElevated,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: textPrimary,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return textPrimary;
            }
            return textTertiary;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return success;
            }
            return surfaceContainer;
          }),
        ),
      );

  /// Alias pour la compatibilité (pointe vers darkTheme)
  static ThemeData get lightTheme => darkTheme;
}

/// Carte avec effet glassmorphism (flou d'arriere-plan) optimisee pour le mode sombre.
/// Utilisee pour les elements de contenu principaux avec un effet visuel premium.
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
    final bgColor = backgroundColor ??
        (elevated ? AppTheme.surfaceElevated : AppTheme.surface);

    final card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.4),
        ),
        boxShadow: elevated ? AppTheme.shadowMD : AppTheme.shadowSM,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.paddingLG),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Badge de statut compact avec couleur de fond et bordure subtile.
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
    // Utiliser le fond personnalisé ou générer un fond subtil
    final bgColor = backgroundColor ?? color.withValues(alpha: 0.15);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
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
    final textColor = outlined ? buttonColor : AppTheme.background;

    return Material(
      color: outlined ? Colors.transparent : buttonColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        splashColor: buttonColor.withValues(alpha: 0.1),
        highlightColor: buttonColor.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 16,
            vertical: small ? 8 : 10,
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
                  fontWeight: FontWeight.w600,
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
