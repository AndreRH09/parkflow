import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/ui/pages/driver_home_page.dart';
import 'package:parkflow/ui/pages/host_home_page.dart';
import 'package:parkflow/ui/pages/login_page.dart';
import 'package:parkflow/ui/pages/parking_config_page.dart';
import 'package:parkflow/ui/pages/profile_onboarding.dart';
import 'package:parkflow/ui/pages/role_selection_page.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestLocationPermission();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestLocationPermission() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (_) {}
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(appInitProvider);

    return MaterialApp(
      title: 'ParkFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: init.when(
        loading: () => const _SplashScreen(),
        error: (e, __) => _ErrorScreen(error: e.toString()),
        data: (_) {
          final authState = ref.watch(authStateProvider);
          return authState.when(
            loading: () => const LoginPage(),
            error: (_, __) => const LoginPage(),
            data: (user) {
              if (user == null) return const LoginPage();
              if (user.needsOnboarding) return const ProfileOnboardingPage();
              if (user.needsRoleSelection) return const RoleSelectionPage();
              if (user.needsGarageSetup) return const ParkingConfigPage();
              return user.role == 'host'
                  ? const HostHomePage()
                  : const DriverHomePage();
            },
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      body: Center(
        child: Image.asset(
          'lib/ui/assets/BannerParkFlow.png',
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String? error;
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brightSnow,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.dustGray),
              const SizedBox(height: 16),
              const Text(
                'Error de inicio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.graphite,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
