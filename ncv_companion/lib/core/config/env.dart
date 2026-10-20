/// Compile-time configuration injected with --dart-define-from-file=config/env.json
/// The anon key is public by design; security is enforced by Row Level Security.
/// Never place the service-role key in this app.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
