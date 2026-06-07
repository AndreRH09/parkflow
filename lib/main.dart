import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/config/app_config.dart';
import 'package:parkflow/ui/pages/login_page.dart';
import 'package:parkflow/ui/pages/profile_onboarding.dart';
import 'package:parkflow/ui/pages/role_selection_page.dart';
import 'package:parkflow/ui/theme/app_theme.dart';
import 'package:parkflow/dependency_injection/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabasePublishableKey, // ignore: deprecated_member_use
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'ParkFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginPage();
          if (user.needsOnboarding) return const ProfileOnboardingPage();
          if (user.needsRoleSelection) return const RoleSelectionPage();
          return const LoginPage(); // placeholder hasta DriverHomePage / HostHomePage
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => const LoginPage(),
      ),
    );
  }
}
