/// Puja de un conductor hacia una cochera del anfitrión.
/// Tabla: bids. Campos `driverName`/`driverAvatarUrl`/`driverRating`/`spotAddress`
/// se rellenan via join cuando se consultan las solicitudes entrantes.
class Bid {
  final String id;
  final String driverId;
  final String hostId;
  final String spotId;
  final double proposedPricePerHour;
  final DateTime startTime;
  final double hoursRequested;
  final double totalAmount;
  final String? vehiclePlate;
  final Map<String, dynamic>? vehicleDimensions;
  final String status; // pending | accepted | rejected | countered | expired
  final DateTime? expiresAt;
  final DateTime createdAt;

  // Joined (opcional)
  final String? driverName;
  final String? driverAvatarUrl;
  final double? driverRating;
  final String? spotAddress;

  const Bid({
    required this.id,
    required this.driverId,
    required this.hostId,
    required this.spotId,
    required this.proposedPricePerHour,
    required this.startTime,
    required this.hoursRequested,
    required this.totalAmount,
    this.vehiclePlate,
    this.vehicleDimensions,
    this.status = 'pending',
    this.expiresAt,
    required this.createdAt,
    this.driverName,
    this.driverAvatarUrl,
    this.driverRating,
    this.spotAddress,
  });

  bool get isPending => status == 'pending';
  bool get isExpired =>
      status == 'expired' ||
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  DateTime get endTime =>
      startTime.add(Duration(minutes: (hoursRequested * 60).round()));

  factory Bid.fromMap(Map<String, dynamic> map) {
    final driver = map['driver'] as Map<String, dynamic>?;
    final spot = map['spot'] as Map<String, dynamic>?;
    return Bid(
      id: map['id'] as String,
      driverId: map['driver_id'] as String,
      hostId: map['host_id'] as String,
      spotId: map['spot_id'] as String,
      proposedPricePerHour:
          (map['proposed_price_per_hour'] as num).toDouble(),
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      hoursRequested: (map['hours_requested'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      vehiclePlate: map['vehicle_plate'] as String?,
      vehicleDimensions: map['vehicle_dimensions'] as Map<String, dynamic>?,
      status: (map['status'] as String?) ?? 'pending',
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      driverName: driver?['full_name'] as String?,
      driverAvatarUrl: driver?['avatar_url'] as String?,
      driverRating: (driver?['rating'] as num?)?.toDouble(),
      spotAddress: spot?['address'] as String?,
    );
  }
}
