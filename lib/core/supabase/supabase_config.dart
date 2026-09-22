/// Supabase project credentials.
///
/// These are read from `--dart-define` values so the real project URL/key
/// never has to be hard-coded or committed. Provide them at run/build time:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
///
///   flutter build web \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
///
/// Or put them in a `supabase.env.json` file (gitignored) and run with
/// `--dart-define-from-file=supabase.env.json`. See README.md for the full
/// setup walkthrough, including the Vercel build command.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT-REF.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-SUPABASE-ANON-KEY',
  );

  static bool get isConfigured =>
      !url.contains('YOUR-PROJECT-REF') && !anonKey.contains('YOUR-SUPABASE-ANON-KEY');
}
