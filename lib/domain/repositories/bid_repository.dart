import 'package:parkflow/domain/entities/bid.dart';

abstract class BidRepository {
  /// Pujas entrantes para el anfitrión (incluye datos del conductor y la cochera).
  Future<List<Bid>> getIncomingBids(String hostId);

  /// Acepta la puja: marca `accepted` y crea la reserva (booking) via RPC.
  Future<void> acceptBid(String bidId);

  /// Rechaza la puja: marca `rejected`.
  Future<void> rejectBid(String bidId);

  /// Driver: crea nueva puja (HU-07).
  Future<String> createBid({
    required String hostId,
    required String spotId,
    required double proposedPricePerHour,
    required DateTime startTime,
    required double hoursRequested,
    String? vehiclePlate,
    Map<String, dynamic>? vehicleDimensions,
  });

  /// Driver: historial de pujas del conductor (HU-08).
  Future<List<Bid>> getDriverBids(String driverId);
}
