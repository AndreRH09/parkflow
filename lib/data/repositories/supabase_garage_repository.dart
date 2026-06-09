import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/domain/entities/garage.dart';
import 'package:parkflow/domain/repositories/garage_repository.dart';

class SupabaseGarageRepository implements GarageRepository {
  final SupabaseClient _client;

  SupabaseGarageRepository(this._client);

  @override
  Future<String> uploadGaragePhoto({
    required String hostId,
    required int index,
    required Uint8List imageBytes,
    required String extension,
  }) async {
    final path = '$hostId/photo_$index';

    try {
      final existing =
          await _client.storage.from('garage-photos').list(path: hostId);
      final match = existing.where((f) => f.name == 'photo_$index').toList();
      if (match.isNotEmpty) {
        await _client.storage.from('garage-photos').remove([path]);
      }
    } catch (_) {}

    await _client.storage.from('garage-photos').uploadBinary(
      path,
      imageBytes,
      fileOptions: FileOptions(contentType: 'image/$extension', upsert: true),
    );

    final baseUrl =
        _client.storage.from('garage-photos').getPublicUrl(path);
    return '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<Garage> saveGarage({
    required String hostId,
    required String address,
    required double basePricePerHour,
    required List<String> vehicleTypes,
    required Map<String, dynamic> features,
    double? width,
    double? height,
    required List<String> photoUrls,
    double latitude = 0,
    double longitude = 0,
  }) async {
    final spotId = await _client.rpc('insert_parking_spot', params: {
      'p_host_id': hostId,
      'p_address': address,
      'p_base_price': basePricePerHour,
      'p_vehicle_types': vehicleTypes,
      'p_features': features,
      'p_width': width,
      'p_height': height,
      'p_photo_urls': photoUrls,
      'p_lat': latitude,
      'p_lng': longitude,
    }) as String;

    final row = await _client
        .from('parking_spots')
        .select()
        .eq('id', spotId)
        .single();

    return Garage.fromMap(row);
  }
}
