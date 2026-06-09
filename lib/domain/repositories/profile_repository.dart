import 'dart:typed_data';

abstract class ProfileRepository {
  Future<void> saveProfile({
    required String userId,
    required String fullName,
    required int age,
    required String dni,
  });

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? city,
    String? avatarUrl,
  });

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String extension,
  });
}
