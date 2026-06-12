import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/domain/entities/booking.dart';
import 'package:parkflow/domain/repositories/booking_repository.dart';

class SupabaseBookingRepository implements BookingRepository {
  final SupabaseClient _client;

  SupabaseBookingRepository(this._client);

  @override
  Future<List<Booking>> getHostBookings(String hostId) async {
    final rows = await _client
        .from('bookings')
        .select()
        .eq('host_id', hostId)
        .order('start_time', ascending: false);

    return (rows as List)
        .map((r) => Booking.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
