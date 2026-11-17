/// Build-time configuration. Nothing secret lives in the source:
/// pass values with --dart-define (see README / build_apk.sh).
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  // Supabase publishable keys are intended for client apps; RLS protects data.
  // supabase_flutter still names its initialize parameter `anonKey`.
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Deep link used by Google / Apple OAuth to return to the app.
  static const oauthRedirect = 'io.supabase.sayedaldukan://login-callback/';
}

class ConfigException implements Exception {
  const ConfigException();
}
