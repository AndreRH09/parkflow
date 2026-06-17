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
        .select('*, spot:parking_spots!bookings_spot_id_fkey(address)')
        .eq('host_id', hostId)
        .order('start_time', ascending: false);

    return (rows as List)
        .map((r) => Booking.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Booking>> getDriverBookings(String driverId) async {
    final rows = await _client
        .from('bookings')
        .select('*, spot:parking_spots!bookings_spot_id_fkey(address)')
        .eq('driver_id', driverId)
        .order('start_time', ascending: false);

    return (rows as List)
        .map((r) => Booking.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> extendBooking(String bookingId, double extraHours) async {
    final result = await _client.rpc('extend_booking', params: {
      'p_booking_id': bookingId,
      'p_extra_hours': extraHours,
    });
    return result as String;
  }
}
