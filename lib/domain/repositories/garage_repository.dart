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
}
