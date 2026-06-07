import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/config/app_config.dart';
import 'package:parkflow/domain/entities/user_profile.dart';
import 'package:parkflow/domain/repositories/auth_repository.dart';
import 'package:parkflow/domain/repositories/profile_repository.dart';
import 'package:parkflow/data/repositories/supabase_auth_repository.dart';
import 'package:parkflow/data/repositories/supabase_profile_repository.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
});

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.read(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.read(supabaseClientProvider)),
);

final authStateProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);
