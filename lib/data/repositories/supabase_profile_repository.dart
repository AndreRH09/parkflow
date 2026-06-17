import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<void> saveProfile({
    required String userId,
    required String fullName,
    required int age,
    required String dni,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'age': age,
      'dni': dni,
      'profile_complete': true,
    }, onConflict: 'id');
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? city,
    String? avatarUrl,
    String? vehicleType,
    String? vehiclePlate,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (city != null) updates['city'] = city;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (vehicleType != null) updates['vehicle_type'] = vehicleType;
    if (vehiclePlate != null) updates['vehicle_plate'] = vehiclePlate;
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String extension,
  }) async {
    const filename = 'avatar';
    final path = '$userId/$filename';

    // Delete all existing files in user's folder (removes orphaned avatar.jpg, etc.)
    try {
      final existing =
          await _client.storage.from('avatars').list(path: userId);
      if (existing.isNotEmpty) {
        final oldPaths = existing.map((f) => '$userId/${f.name}').toList();
        await _client.storage.from('avatars').remove(oldPaths);
      }
    } catch (_) {}

    await _client.storage.from('avatars').uploadBinary(
      path,
      imageBytes,
      fileOptions: FileOptions(contentType: 'image/$extension', upsert: true),
    );

    // Timestamp busts NetworkImage cache so Flutter fetches the new file
    final baseUrl = _client.storage.from('avatars').getPublicUrl(path);
    return '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
