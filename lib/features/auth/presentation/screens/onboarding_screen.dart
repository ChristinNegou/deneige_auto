import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCheckingAuth = true;

  List<OnboardingContent> _getPages(AppLocalizations l10n) {
    return [
      OnboardingContent(
        title: l10n.onboarding_title1,
        description: l10n.onboarding_desc1,
        icon: Icons.ac_unit_rounded,
      ),
      OnboardingContent(
        title: l10n.onboarding_title2,
        description: l10n.onboarding_desc2,
        icon: Icons.event_available_rounded,
      ),
      OnboardingContent(
        title: l10n.onboarding_title3,
        description: l10n.onboarding_desc3,
        icon: Icons.place_rounded,
      ),
      OnboardingContent(
        title: l10n.onboarding_title4,
        description: l10n.onboarding_desc4,
        icon: Icons.credit_card_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Vérifier l'état d'auth après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authState = context.read<AuthBloc>().state;

    // Si déjà authentifié, ne rien faire - la navigation est gérée par deneigeauto_app.dart
    if (authState is AuthAuthenticated) {
      return;
    }

    // Si l'état est final (non authentifié ou erreur), afficher l'onboarding
    if (authState is AuthUnauthenticated || authState is AuthError) {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
      return;
    }

    // Si l'état est initial ou loading, attendre la fin de la vérification
    // Le BlocListener ci-dessous gérera le changement d'état
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage(List<OnboardingContent> pages) {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAccountTypeSelection();
    }
  }

  void _skipOnboarding() {
    _goToAccountTypeSelection();
  }

  void _goToAccountTypeSelection() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.accountType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Si l'état change vers non-authentifié ou erreur, afficher l'onboarding
        if ((state is AuthUnauthenticated || state is AuthError) && mounted) {
          setState(() {
            _isCheckingAuth = false;
          });
        }
        // Si authentifié, la navigation est gérée par deneigeauto_app.dart
      },
      child: _isCheckingAuth
          ? _buildLoadingScreen()
          : _buildOnboardingContent(l10n, pages),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou icône de l'app
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppTheme.shadowLG,
              ),
              child: const Icon(
                Icons.ac_unit_rounded,
                color: AppTheme.onPrimary,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingContent(
      AppLocalizations l10n, List<OnboardingContent> pages) {
    final isLast = _currentPage == pages.length - 1;
    final buttonLabel = Text(isLast ? l10n.onboarding_start : l10n.common_next);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progression et bouton Passer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
              child: Row(
                children: [
                  ...List.generate(
                    pages.length,
                    (index) => _buildPageIndicator(index, pages),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: isLast ? null : _skipOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                      child: Text(l10n.common_skip),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) => _buildPage(pages[index]),
              ),
            ),

            // Suivant, puis Commencer (action cle, en orange)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLast
                    ? FilledButton(
                        key: const ValueKey('start'),
                        onPressed: () => _nextPage(pages),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: buttonLabel,
                      )
                    : ElevatedButton(
                        key: const ValueKey('next'),
                        onPressed: () => _nextPage(pages),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: buttonLabel,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Une etape : grand panneau bleu nuit avec l'icone, puis titre et texte.
  Widget _buildPage(OnboardingContent content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                children: [
                  // Flocons discrets en filigrane
                  Positioned(
                    top: 24,
                    right: 28,
                    child: Icon(
                      Icons.ac_unit_rounded,
                      size: 28,
                      color: AppTheme.onPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  Positioned(
                    bottom: 36,
                    left: 32,
                    child: Icon(
                      Icons.ac_unit_rounded,
                      size: 20,
                      color: AppTheme.onPrimary.withValues(alpha: 0.06),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: AppTheme.onPrimary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        content.icon,
                        size: 60,
                        color: AppTheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            content.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content.description,
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index, List<OnboardingContent> pages) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(right: 6),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : AppTheme.border,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
    );
  }
}

// Modèle pour le contenu de l'onboarding
class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
  });
}
