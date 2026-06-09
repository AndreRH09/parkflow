import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/ui/pages/profile_page.dart';
import 'package:parkflow/ui/theme/app_theme.dart';
import 'package:parkflow/ui/widgets/app_bottom_nav.dart';

class HostHomePage extends ConsumerStatefulWidget {
  const HostHomePage({super.key});

  @override
  ConsumerState<HostHomePage> createState() => _HostHomePageState();
}

class _HostHomePageState extends ConsumerState<HostHomePage> {
  int _navIndex = 0;
  int _filterIndex = 0;

  static const _navItems = [
    AppNavItem(icon: Icons.home_rounded, label: 'Home'),
    AppNavItem(icon: Icons.calendar_month_rounded, label: 'Reservas'),
    AppNavItem(icon: Icons.garage_rounded, label: 'Cochera'),
    AppNavItem(icon: Icons.settings_rounded, label: 'Config'),
  ];

  static const _filters = ['Todo', 'Estacionamiento', 'Vehiculo', 'Moto', 'Pickup'];

  // Placeholder spot data until Supabase integration
  static const _mockSpots = [
    _SpotData(name: 'Garaje Centro', address: 'Av. Ejercito 120, Arequipa', price: 5.00, rating: 4.5),
    _SpotData(name: 'Plaza Parking', address: 'Calle Mercaderes 45, Arequipa', price: 3.50, rating: 4.2),
    _SpotData(name: 'Cochera Norte', address: 'Av. Aviacion 890, Arequipa', price: 4.00, rating: 4.8),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final firstName = user?.fullName?.split(' ').first ?? 'Anfitrion';

    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _navIndex,
          children: [
            _buildHomeTab(context, firstName, user?.avatarUrl),
            _buildPlaceholder('Solicitudes', Icons.inbox_rounded),
            _buildPlaceholder('Mi Cochera', Icons.garage_rounded),
            _buildPlaceholder('Configuracion', Icons.settings_rounded),
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

  Widget _buildHomeTab(BuildContext context, String firstName, String? avatarUrl) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, firstName, avatarUrl),
                const SizedBox(height: 20),
                _buildSearchBar(context),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildMapPlaceholder()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              'Cocheras Populares',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.graphite,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildSpotCards()),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String firstName, String? avatarUrl) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.dustGray,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person_rounded, color: AppColors.graphite, size: 28)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                firstName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.graphite,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        _IconButton(
          icon: Icons.menu_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Buscar cochera...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.graphite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.mustard, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == _filterIndex;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.graphite : AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.graphite : AppColors.dustGray,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.graphite.withAlpha(30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.white : AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.dustGray.withAlpha(60),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.dustGray),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 44, color: AppColors.textSecondary.withAlpha(120)),
              const SizedBox(height: 8),
              const Text(
                'Mapa Mapbox',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
              ),
              const Text(
                'Proximamente',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mustard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.my_location_rounded, size: 14, color: AppColors.graphite),
                  SizedBox(width: 4),
                  Text(
                    'Mi ubicacion',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.graphite,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCards() {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _mockSpots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) => _SpotCard(spot: _mockSpots[i]),
      ),
    );
  }

  Widget _buildPlaceholder(String label, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.dustGray),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Proximamente',
            style: TextStyle(
              color: AppColors.dustGray,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spot card ────────────────────────────────────────────────────────────────

class _SpotData {
  final String name;
  final String address;
  final double price;
  final double rating;
  const _SpotData({
    required this.name,
    required this.address,
    required this.price,
    required this.rating,
  });
}

class _SpotCard extends StatelessWidget {
  final _SpotData spot;
  const _SpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle / spot image placeholder
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.dustGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: const Center(
              child: Icon(Icons.directions_car_rounded,
                  size: 48, color: AppColors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.graphite,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      spot.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.graphite,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        spot.address,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'S/ ${spot.price.toStringAsFixed(2)}/hr',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.graphite,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.graphite,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_outward_rounded,
                          size: 16, color: AppColors.mustard),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared icon button ────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withAlpha(12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.graphite, size: 22),
      ),
    );
  }
}
