import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/config/app_config.dart';
import 'package:parkflow/domain/entities/user_profile.dart';
import 'package:parkflow/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  UserProfile? _cachedProfile;
  bool _googleInitialized = false;

  SupabaseAuthRepository(this._client);

  Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleWebClientId,
    );
    _googleInitialized = true;
  }

  @override
  UserProfile? get currentUser => _cachedProfile;

  @override
  Stream<UserProfile?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) {
        _cachedProfile = null;
        return null;
      }
      _cachedProfile = await _fetchProfile(session.user.id);
      return _cachedProfile;
    });
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    await _ensureGoogleInit();

    final googleUser = await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('No ID token received from Google');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    if (response.user == null) {
      throw Exception('Supabase authentication failed');
    }

    final profile = await _fetchProfile(response.user!.id);
    _cachedProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Credenciales incorrectas');
    final profile = await _fetchProfile(response.user!.id);
    _cachedProfile = profile;
    return profile;
  }

  @override
  Future<UserProfile> registerWithEmail(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Error al crear la cuenta');
    if (response.session == null) {
      throw Exception('Confirma tu correo electronico para activar la cuenta');
    }
    final profile = await _fetchProfile(response.user!.id);
    _cachedProfile = profile;
    return profile;
  }

  @override
  Future<void> signOut() async {
    try {
      await _ensureGoogleInit();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _client.auth.signOut();
    _cachedProfile = null;
  }

  Future<UserProfile> _fetchProfile(String userId) async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .limit(1);
    if (rows.isEmpty) {
      return UserProfile(id: userId);
    }
    return UserProfile.fromMap(rows.first);
  }
}
