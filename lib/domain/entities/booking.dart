/// Reserva confirmada (resultado de aceptar una puja).
/// Tabla: bookings. Usada por HU-13 (ganancias del anfitrión).
class Booking {
  final String id;
  final String bidId;
  final String driverId;
  final String hostId;
  final String spotId;
  final double pricePerHour;
  final DateTime startTime;
  final DateTime endTime;
  final double totalAmount;
  final String? vehiclePlate;
  final String status; // reserved | active | completed | cancelled
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.bidId,
    required this.driverId,
    required this.hostId,
    required this.spotId,
    required this.pricePerHour,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    this.vehiclePlate,
    this.status = 'reserved',
    required this.createdAt,
  });

  bool get isCancelled => status == 'cancelled';

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      bidId: map['bid_id'] as String,
      driverId: map['driver_id'] as String,
      hostId: map['host_id'] as String,
      spotId: map['spot_id'] as String,
      pricePerHour: (map['price_per_hour'] as num).toDouble(),
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: DateTime.parse(map['end_time'] as String).toLocal(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      vehiclePlate: map['vehicle_plate'] as String?,
      status: (map['status'] as String?) ?? 'reserved',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
