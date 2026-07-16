// Valores inyectados en tiempo de compilación desde variables de entorno.
// Para Vercel o cualquier hosting: pasa estas variables en el comando de build.
class AppConfig {
  // fromEnvironment debe ser const: en web lanza UnsupportedOperation si no lo es.
  static const _supabaseUrlRaw = String.fromEnvironment('SUPABASE_URL');
  static const _anonKeyRaw = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _googleWebClientIdRaw =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static String get supabaseUrl => _supabaseUrlRaw
      .trim()
      .replaceAll(RegExp(r'/(auth|rest)/v1/?$'), '')
      .replaceAll(RegExp(r'/+$'), '');

  static String get anonKey => _anonKeyRaw.trim();

  static String get googleWebClientId => _googleWebClientIdRaw.trim();
}
