import 'package:parkflow/domain/entities/bid.dart';

abstract class BidRepository {
  /// Pujas entrantes para el anfitrión (incluye datos del conductor y la cochera).
  Future<List<Bid>> getIncomingBids(String hostId);

  /// Acepta la puja: marca `accepted` y crea la reserva (booking) via RPC.
  Future<void> acceptBid(String bidId);

  /// Rechaza la puja: marca `rejected`.
  Future<void> rejectBid(String bidId);
}
