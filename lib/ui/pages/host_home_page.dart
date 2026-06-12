import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/domain/entities/garage.dart';
import 'package:parkflow/ui/pages/availability_page.dart';
import 'package:parkflow/ui/pages/earnings_page.dart';
import 'package:parkflow/ui/pages/parking_config_page.dart';
import 'package:parkflow/ui/pages/profile_page.dart';
import 'package:parkflow/ui/pages/requests_page.dart';
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

  Future<void> _openConfig() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ParkingConfigPage()),
    );
    ref.invalidate(myGaragesProvider);
  }

  void _openEarnings() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EarningsPage()),
      );

  void _openAvailability(Garage garage) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AvailabilityPage(garage: garage)),
      );

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
            const RequestsPage(embedded: true),
            _buildGarageTab(),
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
                _buildQuickActions(),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Cocheras',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.graphite,
                    fontFamily: 'Inter',
                  ),
                ),
                GestureDetector(
                  onTap: _openConfig,
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle_rounded,
                          size: 18, color: AppColors.graphite),
                      SizedBox(width: 4),
                      Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.graphite,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildGarageCarousel()),
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Ganancias',
            onTap: _openEarnings,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.inbox_rounded,
            label: 'Solicitudes',
            onTap: () => setState(() => _navIndex = 1),
          ),
        ),
      ],
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

  Widget _buildGarageCarousel() {
    final garagesAsync = ref.watch(myGaragesProvider);
    return garagesAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 240,
        child: Center(
          child: Text(
            'Error al cargar cocheras',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
      data: (garages) {
        if (garages.isEmpty) return _buildEmptyGarages();
        return SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: garages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => _GarageCard(
              garage: garages[i],
              onTap: () => _openAvailability(garages[i]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyGarages() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.dustGray),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.garage_rounded, size: 44, color: AppColors.dustGray),
          const SizedBox(height: 10),
          const Text(
            'Aun no tienes cocheras',
            style: TextStyle(
              color: AppColors.graphite,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Publica tu primer espacio',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _openConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mustard,
              foregroundColor: AppColors.graphite,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Agregar cochera',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cochera tab (full list) ──────────────────────────────────────────────────

  Widget _buildGarageTab() {
    final garagesAsync = ref.watch(myGaragesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myGaragesProvider),
      child: garagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'Error al cargar cocheras',
                style: TextStyle(
                    color: AppColors.textSecondary, fontFamily: 'Inter'),
              ),
            ),
          ],
        ),
        data: (garages) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mi Cochera',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.graphite,
                        fontFamily: 'Inter',
                      ),
                    ),
                    _IconButton(icon: Icons.add_rounded, onTap: _openConfig),
                  ],
                ),
              ),
            ),
            if (garages.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _buildEmptyGarages(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList.separated(
                  itemCount: garages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _GarageListTile(
                    garage: garages[i],
                    onTap: () => _openAvailability(garages[i]),
                  ),
                ),
              ),
          ],
        ),
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

// ── Primary photo helper ──────────────────────────────────────────────────────

class _GaragePhoto extends StatelessWidget {
  final String? url;
  final double size;
  const _GaragePhoto({required this.url, this.size = 48});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Center(
        child: Icon(Icons.directions_car_rounded,
            size: size, color: AppColors.white),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (ctx, child, progress) => progress == null
          ? child
          : const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      errorBuilder: (_, __, ___) => Center(
        child: Icon(Icons.broken_image_rounded,
            size: size, color: AppColors.white),
      ),
    );
  }
}

// ── Garage card (home carousel) ───────────────────────────────────────────────

class _GarageCard extends StatelessWidget {
  final Garage garage;
  final VoidCallback? onTap;
  const _GarageCard({required this.garage, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          // Primary photo
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            child: Container(
              height: 120,
              color: AppColors.dustGray,
              child: _GaragePhoto(url: garage.primaryPhotoUrl),
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
                        garage.address,
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
                      garage.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.graphite,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _StatusPill(active: garage.isActive),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'S/ ${garage.basePricePerHour.toStringAsFixed(2)}/hr',
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
      ),
    );
  }
}

// ── Garage list tile (Cochera tab) ────────────────────────────────────────────

class _GarageListTile extends StatelessWidget {
  final Garage garage;
  final VoidCallback? onTap;
  const _GarageListTile({required this.garage, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.graphite.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
            child: Container(
              width: 110,
              height: 110,
              color: AppColors.dustGray,
              child: _GaragePhoto(url: garage.primaryPhotoUrl, size: 36),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    garage.address,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.graphite,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusPill(active: garage.isActive),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        garage.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.graphite,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'S/ ${garage.basePricePerHour.toStringAsFixed(2)}/hr',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool active;
  const _StatusPill({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        active ? 'Activa' : 'Inactiva',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ── Quick action button (home tab) ───────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.graphite.withAlpha(12),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.mustard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.graphite),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.graphite,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
