import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkflow/config/app_config.dart';
import 'package:parkflow/domain/entities/user_profile.dart';
import 'package:parkflow/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  UserProfile? _cachedProfile;

  SupabaseAuthRepository(this._client)
      : _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: AppConfig.googleWebClientId,
        );

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
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('No ID token received from Google');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
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
    await _googleSignIn.signOut();
    await _client.auth.signOut();
    _cachedProfile = null;
  }

  @override
  Future<void> deleteAccount() async {
    await _client.rpc('delete_user_account');
    await _googleSignIn.signOut();
    await _client.auth.signOut();
    _cachedProfile = null;
  }

  Future<UserProfile> _fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromMap(data);
  }
}
