class Garage {
  final String id;
  final String hostId;
  final String address;
  final double? width;
  final double? height;
  final List<String> vehicleTypes;
  final Map<String, dynamic> features;
  final double basePricePerHour;
  final List<String> photoUrls;
  final bool isActive;
  final double latitude;
  final double longitude;

  const Garage({
    required this.id,
    required this.hostId,
    required this.address,
    this.width,
    this.height,
    this.vehicleTypes = const [],
    this.features = const {},
    required this.basePricePerHour,
    this.photoUrls = const [],
    this.isActive = true,
    this.latitude = 0,
    this.longitude = 0,
  });

  String? get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  factory Garage.fromMap(Map<String, dynamic> map) {
    return Garage(
      id: map['id'] as String,
      hostId: map['host_id'] as String,
      address: map['address'] as String,
      width: (map['width'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      vehicleTypes: (map['vehicle_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      features: (map['features'] as Map<String, dynamic>?) ?? {},
      basePricePerHour: (map['base_price_per_hour'] as num).toDouble(),
      photoUrls: (map['photo_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}
