import 'package:parkflow/domain/entities/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  Future<UserProfile> signInWithGoogle();
  Future<UserProfile> signInWithEmail(String email, String password);
  Future<UserProfile> registerWithEmail(String email, String password);
  Future<void> signOut();
  UserProfile? get currentUser;
}