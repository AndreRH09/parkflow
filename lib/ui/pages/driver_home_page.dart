import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/domain/entities/garage.dart';
import 'package:parkflow/ui/theme/app_theme.dart';
import 'package:parkflow/ui/widgets/app_bottom_nav.dart';
import 'package:parkflow/ui/pages/profile_page.dart';
import 'package:parkflow/ui/pages/garage_detail_sheet.dart';

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
    final user = ref.watch(authStateProvider).value;
    final firstName = user?.fullName?.split(' ').first ?? 'Conductor';

    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _navIndex,
          children: [
            _DriverHomeTab(firstName: firstName, avatarUrl: user?.avatarUrl),
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

class _DriverHomeTab extends ConsumerStatefulWidget {
  final String firstName;
  final String? avatarUrl;

  const _DriverHomeTab({required this.firstName, this.avatarUrl});

  @override
  ConsumerState<_DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends ConsumerState<_DriverHomeTab> {
  late MapController _mapController;
  double? _lat;
  double? _lng;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openDetailSheet(Garage garage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GarageDetailSheet(garage: garage),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lat == null || _lng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final nearbyGarages = ref.watch(nearbyGaragesProvider((lat: _lat!, lng: _lng!)));

    return SingleChildScrollView(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(context, widget.firstName, widget.avatarUrl),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      height: 400,
                      color: AppColors.dustGray.withValues(alpha: 0.15),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(_lat!, _lng!),
                          initialZoom: 15,
                          minZoom: 2,
                          maxZoom: 19,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.parkflow',
                            maxZoom: 19,
                          ),
                          nearbyGarages.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (garages) => MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_lat!, _lng!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                                ...garages.map((g) {
                                  return Marker(
                                    point: LatLng(g.latitude, g.longitude),
                                    width: 40,
                                    height: 40,
                                    child: GestureDetector(
                                      onTap: () => _openDetailSheet(g),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.mustard,
                                        size: 32,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: 0,
                  right: 0,
                  child: nearbyGarages.when(
                    loading: () => const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SizedBox(
                      height: 140,
                      child: Center(child: Text('Error: $e')),
                    ),
                    data: (garages) => _buildCompactGarageCarousel(garages),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String firstName, String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.dustGray,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person_rounded, color: AppColors.graphite, size: 24)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphite,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.graphite.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.menu_rounded, color: AppColors.graphite, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Parking Location...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.dustGray),
          suffixIcon: GestureDetector(
            onTap: _initLocation,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mustard.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.mustard),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
        onChanged: (_) {},
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Parking', 'Vehicle', 'Motorbike'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = f == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.graphite : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.graphite.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.graphite,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactGarageCarousel(List<Garage> garages) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.brightSnow,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: garages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_rounded, size: 32, color: AppColors.dustGray),
                  const SizedBox(height: 6),
                  const Text(
                    'No nearby parking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.graphite,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: garages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _CompactGarageCard(
                    garage: garages[i],
                    onTap: () => _openDetailSheet(garages[i]),
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _CompactGarageCard extends StatelessWidget {
  final Garage garage;
  final VoidCallback onTap;

  const _CompactGarageCard({required this.garage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photoUrl = garage.primaryPhotoUrl;
    final ratingText = garage.rating.toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            child: Container(
              height: 80,
              color: AppColors.dustGray.withValues(alpha: 0.2),
              child: photoUrl != null
                  ? Image.network(photoUrl, fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported_rounded,
                      color: AppColors.dustGray, size: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  garage.address ?? 'Parking',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphite,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 10, color: AppColors.mustard),
                    const SizedBox(width: 2),
                    Text(
                      ratingText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.graphite,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${(garage.basePricePerHour ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: const Text(
              'Mis Reservas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.graphite,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        bookings.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.graphite.withAlpha(12),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 44, color: AppColors.dustGray),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin reservas',
                          style: TextStyle(
                            color: AppColors.graphite,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Aún no tienes reservas registradas',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final b = list[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.graphite.withAlpha(12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                b.spotAddress ?? 'Reserva',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.graphite,
                                  fontFamily: 'Inter',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              _statusBadge(b.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Desde: ${b.startTime?.toString() ?? "N/A"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'reserved':
      case 'active':
        bgColor = AppColors.mustard.withAlpha(30);
        textColor = AppColors.mustard;
        break;
      case 'pending':
        bgColor = Colors.orange.withAlpha(30);
        textColor = Colors.orange;
        break;
      case 'cancelled':
      case 'rejected':
        bgColor = Colors.red.withAlpha(30);
        textColor = Colors.red;
        break;
      default:
        bgColor = AppColors.dustGray.withAlpha(30);
        textColor = AppColors.dustGray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
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

