import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parkflow/dependency_injection/providers.dart';
import 'package:parkflow/ui/pages/driver_home_page.dart';
import 'package:parkflow/ui/pages/host_home_page.dart';
import 'package:parkflow/ui/pages/login_page.dart';
import 'package:parkflow/ui/pages/profile_onboarding.dart';
import 'package:parkflow/ui/pages/role_selection_page.dart';
import 'package:parkflow/ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
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
        error: (_, __) => const _SplashScreen(),
        data: (_) {
          final authState = ref.watch(authStateProvider);
          return authState.when(
            loading: () => const LoginPage(),
            error: (_, __) => const LoginPage(),
            data: (user) {
              if (user == null) return const LoginPage();
              if (user.needsOnboarding) return const ProfileOnboardingPage();
              if (user.needsRoleSelection) return const RoleSelectionPage();
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
