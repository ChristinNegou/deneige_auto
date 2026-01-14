import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNavBar(),
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
