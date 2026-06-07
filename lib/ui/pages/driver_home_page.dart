import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/ui/theme/app_theme.dart';
import 'package:parkflow/ui/widgets/app_bottom_nav.dart';

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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_car_rounded,
                  size: 56, color: AppColors.dustGray),
              const SizedBox(height: 16),
              Text(
                'Hola, $firstName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.graphite,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Modulo Driver\nProximamente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
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
