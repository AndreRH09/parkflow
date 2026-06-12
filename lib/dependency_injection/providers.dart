import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/config/app_config.dart';
import 'package:parkflow/domain/entities/user_profile.dart';
import 'package:parkflow/domain/entities/garage.dart';
import 'package:parkflow/domain/entities/bid.dart';
import 'package:parkflow/domain/entities/booking.dart';
import 'package:parkflow/domain/repositories/auth_repository.dart';
import 'package:parkflow/domain/repositories/profile_repository.dart';
import 'package:parkflow/domain/repositories/garage_repository.dart';
import 'package:parkflow/domain/repositories/bid_repository.dart';
import 'package:parkflow/domain/repositories/booking_repository.dart';
import 'package:parkflow/data/repositories/supabase_auth_repository.dart';
import 'package:parkflow/data/repositories/supabase_profile_repository.dart';
import 'package:parkflow/data/repositories/supabase_garage_repository.dart';
import 'package:parkflow/data/repositories/supabase_bid_repository.dart';
import 'package:parkflow/data/repositories/supabase_booking_repository.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.anonKey,
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

final garageRepositoryProvider = Provider<GarageRepository>(
  (ref) => SupabaseGarageRepository(ref.read(supabaseClientProvider)),
);

final bidRepositoryProvider = Provider<BidRepository>(
  (ref) => SupabaseBidRepository(ref.read(supabaseClientProvider)),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => SupabaseBookingRepository(ref.read(supabaseClientProvider)),
);

final authStateProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

/// Cocheras del host autenticado. Se refresca con `ref.invalidate`.
final myGaragesProvider = FutureProvider<List<Garage>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];
  return ref.read(garageRepositoryProvider).getGaragesByHost(user.id);
});

/// Pujas entrantes del host (HU-12). Refresca con `ref.invalidate`.
final incomingBidsProvider = FutureProvider<List<Bid>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];
  return ref.read(bidRepositoryProvider).getIncomingBids(user.id);
});

/// Reservas del host (HU-13 ganancias). Refresca con `ref.invalidate`.
final hostBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];
  return ref.read(bookingRepositoryProvider).getHostBookings(user.id);
});
