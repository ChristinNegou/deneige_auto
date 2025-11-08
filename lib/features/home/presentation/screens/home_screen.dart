import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../reservation/domain/entities/weather.dart';
import '../../domain/entities/weather.dart';
import '../../../../core/utils/time_utils.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/quick_actions_panel.dart';
import '../widgets/upcoming_reservations_list.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({
    Key? key,
    required this.weather,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[400]!,
            Colors.blue[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Météo actuelle',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          weather.condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                weather.icon,
                style: const TextStyle(fontSize: 64),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfo(
                Icons.opacity,
                '${weather.humidity}%',
                'Humidité',
              ),
              _buildWeatherInfo(
                Icons.air,
                '${weather.windSpeed.round()} km/h',
                'Vent',
              ),
              _buildWeatherInfo(
                Icons.ac_unit,
                '${weather.snowDepthCm} cm',
                'Neige',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}


/// Écran principal de l'application affichant un résumé des informations importantes
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données après que le widget soit complètement initialisé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(LoadHomeData());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: _handleStateChanges,
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => _refreshData(context),
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context, state),
                  _buildBody(context, state),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: const _NewReservationFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Gère les changements d'état du Bloc
  void _handleStateChanges(BuildContext context, HomeState state) {
    if (state.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Rafraîchit les données et attend la fin du chargement
  Future<void> _refreshData(BuildContext context) async {
    if (!mounted) return;
    
    context.read<HomeBloc>().add(LoadHomeData());
    
    // Attendre que l'état de chargement soit terminé
    await context.read<HomeBloc>().stream.firstWhere(
      (state) => !state.isLoading,
      orElse: () => context.read<HomeBloc>().state,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => context.read<HomeBloc>().state,
    );
  }

  Widget _buildAppBar(BuildContext context, HomeState state) {
    return SliverAppBar(
      expandedHeight: AppDimensions.appBarExpandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TimeUtils.getGreeting(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
            Text(
              state.user?.firstName ?? 'Utilisateur',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(
          left: AppDimensions.paddingLarge,
          bottom: AppDimensions.paddingMedium,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => _navigateTo(context, AppRoutes.notifications),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profil',
          onPressed: () => _navigateTo(context, AppRoutes.profile),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state.isLoading && state.weather == null) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Carte météo
          if (state.weather != null) ...[
            WeatherCard(weather: state.weather!),
            const SizedBox(height: AppDimensions.spacingMedium),
          ],

          // Message d'alerte météo si nécessaire
          if (state.weather != null && state.weather!.hasSnowAlert) ...[
            _SnowAlertCard(weather: state.weather!),
            const SizedBox(height: AppDimensions.spacingMedium),
          ],

          // Actions rapides
          QuickActionsPanel(
            onNewReservation: () => _navigateTo(context, AppRoutes.newReservation),
            onViewReservations: () => _navigateTo(context, AppRoutes.reservations),
            onViewVehicles: () => _navigateTo(context, AppRoutes.vehicles),
            onViewSubscription: () => _navigateTo(context, AppRoutes.subscription),
          ),
          const SizedBox(height: AppDimensions.spacingLarge),

          // Prochaines réservations
          if (state.upcomingReservations.isNotEmpty) ...[
            _buildReservationsSection(context, state),
          ] else ...[
            const _EmptyReservationsState(),
          ],

          const SizedBox(height: AppDimensions.fabSpacing),
        ]),
      ),
    );
  }

  Widget _buildReservationsSection(BuildContext context, HomeState state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Prochaines réservations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navigateTo(context, AppRoutes.reservations),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        UpcomingReservationsList(
          reservations: state.upcomingReservations,
          onReservationTap: (reservation) {
            _navigateTo(
              context,
              AppRoutes.reservationDetails,
              arguments: reservation.id,
            );
          },
        ),
      ],
    );
  }

  /// Navigation sécurisée avec vérification du montage
  void _navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    if (!mounted) return;
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }
}

/// Widget pour l'alerte neige
class _SnowAlertCard extends StatelessWidget {
  final dynamic weather;

  const _SnowAlertCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[800],
            size: 32,
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerte neige',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Précipitations prévues. Planifiez votre déneigement dès maintenant!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour l'état vide (aucune réservation)
class _EmptyReservationsState extends StatelessWidget {
  const _EmptyReservationsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.ac_unit_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          Text(
            'Aucune réservation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'Planifiez votre premier déneigement pour ne jamais partir en retard!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton d'action flottant pour créer une nouvelle réservation
class _NewReservationFAB extends StatelessWidget {
  const _NewReservationFAB();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fabWidth = width > 400 ? 400.0 : width - AppDimensions.paddingLarge * 2;

    return Container(
      width: fabWidth,
      height: AppDimensions.fabHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColorDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.fabHeight / 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.newReservation);
          },
          borderRadius: BorderRadius.circular(AppDimensions.fabHeight / 2),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: AppDimensions.spacingSmall),
              Text(
                'Planifier un déneigement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

