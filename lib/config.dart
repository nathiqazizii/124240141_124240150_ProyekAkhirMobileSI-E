import 'secrets.dart';

/// Konfigurasi aplikasi. Nilai Supabase diberikan lewat `--dart-define`
/// sehingga tidak pernah di-commit ke repository.
class AppConfig {
  AppConfig._();

  // Default dibaca dari lib/secrets.dart (di-gitignore). --dart-define tetap
  // bisa dipakai dan akan menimpa nilai default ini.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: Secrets.supabaseUrl,
  );
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: Secrets.supabasePublishableKey,
  );

  static bool get isConfigured =>
      supabaseUrl.startsWith('http') &&
      supabaseKey.isNotEmpty &&
      !supabaseKey.startsWith('GANTI_');

  static const String pokeApiBase = 'https://pokeapi.co/api/v2';

  static String artworkUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}
