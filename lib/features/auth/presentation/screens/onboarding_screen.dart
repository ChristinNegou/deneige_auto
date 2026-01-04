import 'package:flutter/material.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_illustration.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: 'Bienvenue sur Déneige Auto',
      description:
          'La solution moderne pour gérer le déneigement de votre propriété en toute simplicité',
      illustrationType: IllustrationType.welcome,
      accentColor: const Color(0xFF00D4FF),
    ),
    OnboardingContent(
      title: 'Réservez en quelques clics',
      description:
          'Planifiez vos services de déneigement selon vos besoins et votre horaire',
      illustrationType: IllustrationType.calendar,
      accentColor: const Color(0xFF3B82F6),
    ),
    OnboardingContent(
      title: 'Suivi en temps réel',
      description:
          'Suivez l\'avancement du déneigement et recevez des notifications instantanées',
      illustrationType: IllustrationType.location,
      accentColor: const Color(0xFF10B981),
    ),
    OnboardingContent(
      title: 'Paiement sécurisé',
      description: 'Payez en toute sécurité et gérez vos factures facilement',
      illustrationType: IllustrationType.payment,
      accentColor: const Color(0xFF8B5CF6),
    ),
  ];

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

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              _pages[_currentPage].accentColor.withValues(alpha: 0.15),
              AppTheme.background,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Bouton Skip
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView avec le contenu
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Indicateurs de page
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
              ),

              // Bouton Suivant/Commencer
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].accentColor,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: _pages[_currentPage]
                          .accentColor
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Commencer'
                          : 'Suivant',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingContent content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image 3D
          AppIllustration(
            type: content.illustrationType,
            width: 220,
            height: 220,
          ),
          const SizedBox(height: 48),

          // Titre
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: content.accentColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? _pages[_currentPage].accentColor
            : AppTheme.textTertiary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Modèle pour le contenu de l'onboarding
class OnboardingContent {
  final String title;
  final String description;
  final IllustrationType illustrationType;
  final Color accentColor;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.illustrationType,
    required this.accentColor,
  });
}
