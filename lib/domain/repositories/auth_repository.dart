import 'package:parkflow/domain/entities/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  /// En web redirige y no retorna perfil; la sesión llega por [authStateChanges].
  Future<void> signInWithGoogle();
  Future<UserProfile> signInWithEmail(String email, String password);
  Future<UserProfile> registerWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> deleteAccount();
  UserProfile? get currentUser;
}