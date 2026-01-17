import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../bloc/worker_availability_bloc.dart';
import '../bloc/worker_jobs_bloc.dart';
import '../bloc/worker_stats_bloc.dart';
import 'worker_home_tab.dart';
import 'worker_earnings_tab.dart';
import 'worker_payments_tab.dart';
import 'worker_profile_tab.dart';

class WorkerMainDashboard extends StatefulWidget {
  const WorkerMainDashboard({super.key});

  /// Permet de changer d'onglet depuis les enfants
  static void switchToTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<_WorkerMainDashboardState>();
    state?._switchToTab(tabIndex);
  }

  /// Index des onglets
  static const int homeTab = 0;
  static const int earningsTab = 1;
  static const int paymentsTab = 2;
  static const int profileTab = 3;

  @override
  State<WorkerMainDashboard> createState() => _WorkerMainDashboardState();
}

class _WorkerMainDashboardState extends State<WorkerMainDashboard> {
  int _currentIndex = 0;

  // FAB draggable state
  double? _fabX;
  double? _fabY;
  bool _isDragging = false;
  static const double _fabSize = 56;
  static const String _fabXKey = 'worker_ai_fab_x';
  static const String _fabYKey = 'worker_ai_fab_y';

  @override
  void initState() {
    super.initState();
    _loadFabPosition();
  }

  Future<void> _loadFabPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_fabXKey);
      final y = prefs.getDouble(_fabYKey);
      if (mounted && x != null && y != null) {
        setState(() {
          _fabX = x;
          _fabY = y;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveFabPosition() async {
    if (_fabX == null || _fabY == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fabXKey, _fabX!);
      await prefs.setDouble(_fabYKey, _fabY!);
    } catch (_) {}
  }

  void _switchToTab(int index) {
    if (index >= 0 && index < _pages.length && _currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  final List<Widget> _pages = const [
    WorkerHomeTab(),
    WorkerEarningsTab(),
    WorkerPaymentsTab(),
    WorkerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<HomeBloc>()),
        BlocProvider(create: (_) => sl<WorkerJobsBloc>()),
        BlocProvider(create: (_) => sl<WorkerAvailabilityBloc>()),
        BlocProvider(create: (_) => sl<WorkerStatsBloc>()),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            _buildDraggableFab(context),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildDraggableFab(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;
    final topPadding = mediaQuery.padding.top;

    const minX = 10.0;
    final maxX = screenWidth - _fabSize - 10;
    final minY = topPadding + 10;
    final maxY =
        screenHeight - _fabSize - bottomPadding - 140; // Above bottom nav

    final currentX = _fabX ?? (screenWidth - _fabSize - 20);
    final currentY = _fabY ?? (screenHeight - _fabSize - bottomPadding - 160);

    final clampedX = currentX.clamp(minX, maxX);
    final clampedY = currentY.clamp(minY, maxY);

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _fabX = ((_fabX ?? currentX) + details.delta.dx).clamp(minX, maxX);
            _fabY = ((_fabY ?? currentY) + details.delta.dy).clamp(minY, maxY);
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          // Snap to nearest edge
          final centerX = screenWidth / 2;
          setState(() {
            if ((_fabX ?? currentX) + _fabSize / 2 < centerX) {
              _fabX = 20;
            } else {
              _fabX = screenWidth - _fabSize - 20;
            }
          });
          _saveFabPosition();
        },
        onTap: () {
          if (!_isDragging) {
            Navigator.pushNamed(context, AppRoutes.aiChat);
          }
        },
        child: AnimatedScale(
          scale: _isDragging ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: _fabSize,
            height: _fabSize,
            decoration: BoxDecoration(
              color: AppTheme.primary2,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary2.withValues(alpha: 0.4),
                  blurRadius: _isDragging ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.trending_up_rounded,
                activeIcon: Icons.trending_up_rounded,
                label: 'Revenus',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Paiements',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
