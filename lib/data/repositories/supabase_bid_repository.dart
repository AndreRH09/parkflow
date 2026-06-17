import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/domain/entities/bid.dart';
import 'package:parkflow/domain/repositories/bid_repository.dart';

class SupabaseBidRepository implements BidRepository {
  final SupabaseClient _client;

  SupabaseBidRepository(this._client);

  @override
  Future<List<Bid>> getIncomingBids(String hostId) async {
    final rows = await _client
        .from('bids')
        .select(
          '*, '
          'driver:profiles!bids_driver_id_fkey(full_name, avatar_url, rating), '
          'spot:parking_spots!bids_spot_id_fkey(address)',
        )
        .eq('host_id', hostId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => Bid.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> acceptBid(String bidId) async {
    // RPC (SECURITY DEFINER): marca accepted + inserta booking. bookings no tiene
    // política INSERT, por eso debe crearse server-side.
    await _client.rpc('accept_bid', params: {'p_bid_id': bidId});
  }

  @override
  Future<void> rejectBid(String bidId) async {
    await _client.from('bids').update({'status': 'rejected'}).eq('id', bidId);
  }

  @override
  Future<String> createBid({
    required String hostId,
    required String spotId,
    required double proposedPricePerHour,
    required DateTime startTime,
    required double hoursRequested,
    String? vehiclePlate,
    Map<String, dynamic>? vehicleDimensions,
  }) async {
    final totalAmount = proposedPricePerHour * hoursRequested;

    final result = await _client.from('bids').insert({
      'host_id': hostId,
      'spot_id': spotId,
      'proposed_price_per_hour': proposedPricePerHour,
      'start_time': startTime.toIso8601String(),
      'hours_requested': hoursRequested,
      'total_amount': totalAmount,
      'vehicle_plate': vehiclePlate,
      'vehicle_dimensions': vehicleDimensions,
      'status': 'pending',
    }).select().single();

    return result['id'] as String;
  }

  @override
  Future<List<Bid>> getDriverBids(String driverId) async {
    final rows = await _client
        .from('bids')
        .select(
          '*, '
          'driver:profiles!bids_driver_id_fkey(full_name, avatar_url, rating), '
          'spot:parking_spots!bids_spot_id_fkey(address)',
        )
        .eq('driver_id', driverId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => Bid.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
