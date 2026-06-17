import 'dart:typed_data';
import 'package:parkflow/domain/entities/garage.dart';

abstract class GarageRepository {
  Future<String> uploadGaragePhoto({
    required String hostId,
    required int index,
    required Uint8List imageBytes,
    required String extension,
  });

  Future<Garage> saveGarage({
    required String hostId,
    required String address,
    required double basePricePerHour,
    required List<String> vehicleTypes,
    required Map<String, dynamic> features,
    double? width,
    double? height,
    required List<String> photoUrls,
    double latitude,
    double longitude,
  });

  Future<List<Garage>> getGaragesByHost(String hostId);

  /// Busca cocheras cercanas (HU-05): geospatial query via nearby_spots RPC.
  Future<List<Garage>> getNearbyGarages(double lat, double lng, {int radiusM = 800});

  /// Actualiza disponibilidad de una cochera (HU-11): switch maestro + horario + días.
  /// `start`/`end` formato 'HH:mm'; `days` enteros 1=Lun..7=Dom.
  Future<void> updateAvailability({
    required String spotId,
    required bool isActive,
    String? start,
    String? end,
    List<int>? days,
  });
}
