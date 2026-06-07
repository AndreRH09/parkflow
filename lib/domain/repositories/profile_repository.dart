abstract class ProfileRepository {
  Future<void> saveProfile({
    required String userId,
    required String fullName,
    required int age,
    required String dni,
  });
}
