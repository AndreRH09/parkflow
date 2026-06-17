import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/domain/entities/garage.dart';
import 'package:parkflow/ui/theme/app_theme.dart';
import 'package:parkflow/ui/widgets/app_bottom_nav.dart';
import 'package:parkflow/ui/pages/profile_page.dart';

class DriverHomePage extends ConsumerStatefulWidget {
  const DriverHomePage({super.key});

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  int _navIndex = 0;

  static const _navItems = [
    AppNavItem(icon: Icons.home_rounded, label: 'Home'),
    AppNavItem(icon: Icons.calendar_month_rounded, label: 'Reservas'),
    AppNavItem(icon: Icons.map_rounded, label: 'Mapa'),
    AppNavItem(icon: Icons.settings_rounded, label: 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    final firstName = ref.watch(authStateProvider).value?.fullName?.split(' ').first ?? 'Conductor';

    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _navIndex,
          children: [
            _DriverHomeTab(firstName: firstName),
            _DriverReservationsTab(),
            _DriverMapTab(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (c) => const ProfilePage()),
                  );
                },
                child: const Text('Ir a Perfil'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _DriverHomeTab extends ConsumerWidget {
  final String firstName;

  const _DriverHomeTab({required this.firstName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBooking = ref.watch(activeBookingProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $firstName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.graphite,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            if (activeBooking.hasValue && activeBooking.value != null)
              _ActiveBookingCard(booking: activeBooking.value!)
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No tienes reservas activas', style: TextStyle(color: AppColors.textSecondary)),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: scroll to map tab or open map
                },
                icon: const Icon(Icons.location_on_rounded),
                label: const Text('Buscar estacionamiento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  final dynamic booking;

  const _ActiveBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reserva activa', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.mustard)),
            const SizedBox(height: 8),
            Text(
              booking.spotAddress ?? 'Ubicación desconocida',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Hasta: ${booking.endTime}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverReservationsTab extends ConsumerWidget {
  const _DriverReservationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(driverBookingsProvider);
    final bids = ref.watch(driverBidsProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reservas y Pujas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.graphite),
            ),
            const SizedBox(height: 16),
            bookings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No tienes reservas', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : Column(
                      children: list
                          .map((b) => Card(
                                color: AppColors.white,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(b.spotAddress ?? 'Reserva'),
                                  subtitle: Text(
                                    'Desde: ${b.startTime?.toString() ?? "N/A"}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: _statusBadge(b.status),
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    switch (status) {
      case 'reserved':
      case 'active':
        bgColor = AppColors.mustard;
        break;
      case 'pending':
        bgColor = Colors.orange;
        break;
      case 'cancelled':
      case 'rejected':
        bgColor = Colors.red;
        break;
      default:
        bgColor = AppColors.dustGray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status,
        style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DriverMapTab extends ConsumerStatefulWidget {
  const _DriverMapTab();

  @override
  ConsumerState<_DriverMapTab> createState() => _DriverMapTabState();
}

class _DriverMapTabState extends ConsumerState<_DriverMapTab> {
  late Position? _currentPosition;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lat == null || _lng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final nearbyGarages = ref.watch(nearbyGaragesProvider((lat: _lat!, lng: _lng!)));

    return Stack(
      children: [
        // ponytail: placeholder for flutter_map implementation (HU-05)
        // OSM tiles + markers for garages
        Container(
          color: AppColors.dustGray.withOpacity(0.1),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_rounded, size: 48, color: AppColors.dustGray),
                const SizedBox(height: 16),
                const Text('Mapa — Tu ubicación:'),
                Text('$_lat, $_lng', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                nearbyGarages.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('Error: $e'),
                  data: (garages) => Text('${garages.length} cocheras cercanas'),
                ),
              ],
            ),
          ),
        ),
        // Search bar (top)
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar dirección...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            // ponytail: TODO Nominatim integration
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}
