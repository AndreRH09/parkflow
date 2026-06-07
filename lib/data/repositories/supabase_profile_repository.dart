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
}
