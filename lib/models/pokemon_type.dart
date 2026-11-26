// ---------------------------------------------------------------------------
// P1 (OOP & Dart): enum dengan method, record, koleksi, dan null safety.
// Dipakai di alur "Analisis Pokémon": detail/dashboard menampilkan kelemahan
// dan ketahanan tipe yang dihitung dari tabel efektivitas ini.
// ---------------------------------------------------------------------------

/// Baris tabel efektivitas serangan satu tipe penyerang.
class _ChartRow {
  final Set<String> twice;
  final Set<String> half;
  final Set<String> zero;
  const _ChartRow(this.twice, this.half, this.zero);
}

/// Tipe penyerang -> (sangat efektif, kurang efektif, tidak berpengaruh).
const Map<String, (String, String, String)> _rawChart = {
  'normal': ('', 'rock steel', 'ghost'),
  'fire': ('grass ice bug steel', 'fire water rock dragon', ''),
  'water': ('fire ground rock', 'water grass dragon', ''),
  'electric': ('water flying', 'electric grass dragon', 'ground'),
  'grass': (
    'water ground rock',
    'fire grass poison flying bug dragon steel',
    ''
  ),
  'ice': ('grass ground flying dragon', 'fire water ice steel', ''),
  'fighting': (
    'normal ice rock dark steel',
    'poison flying psychic bug fairy',
    'ghost'
  ),
  'poison': ('grass fairy', 'poison ground rock ghost', 'steel'),
  'ground': ('fire electric poison rock steel', 'grass bug', 'flying'),
  'flying': ('grass fighting bug', 'electric rock steel', ''),
  'psychic': ('fighting poison', 'psychic steel', 'dark'),
  'bug': (
    'grass psychic dark',
    'fire fighting poison flying ghost steel fairy',
    ''
  ),
  'rock': ('fire ice flying bug', 'fighting ground steel', ''),
  'ghost': ('psychic ghost', 'dark', 'normal'),
  'dragon': ('dragon', 'steel', 'fairy'),
  'dark': ('psychic ghost', 'fighting dark fairy', ''),
  'steel': ('ice rock fairy', 'fire water electric steel', ''),
  'fairy': ('fighting dragon dark', 'fire poison steel', ''),
};

Set<String> _words(String s) =>
    s.isEmpty ? <String>{} : s.split(' ').toSet();

final Map<String, _ChartRow> _chart = {
  for (final e in _rawChart.entries)
    e.key: _ChartRow(_words(e.value.$1), _words(e.value.$2), _words(e.value.$3)),
};

enum PokemonType {
  normal,
  fire,
  water,
  electric,
  grass,
  ice,
  fighting,
  poison,
  ground,
  flying,
  psychic,
  bug,
  rock,
  ghost,
  dragon,
  dark,
  steel,
  fairy;

  String get label => name[0].toUpperCase() + name.substring(1);

  /// Mengubah nama dari API ("fire") menjadi enum; null bila tidak dikenal.
  static PokemonType? tryParse(String raw) {
    for (final t in PokemonType.values) {
      if (t.name == raw) return t;
    }
    return null;
  }

  /// Pengali damage ketika tipe ini menyerang tipe [defender].
  double attackMultiplier(PokemonType defender) {
    final row = _chart[name];
    if (row == null) return 1;
    if (row.zero.contains(defender.name)) return 0;
    if (row.twice.contains(defender.name)) return 2;
    if (row.half.contains(defender.name)) return 0.5;
    return 1;
  }
}

/// Hasil analisis pertahanan sebuah Pokémon (1 atau 2 tipe).
class TypeMatchup {
  /// Tipe penyerang -> pengali damage terhadap Pokémon ini.
  final Map<PokemonType, double> defense;

  const TypeMatchup(this.defense);

  factory TypeMatchup.of(List<String> typeNames) {
    final defenders = typeNames
        .map(PokemonType.tryParse)
        .whereType<PokemonType>()
        .toList();
    final map = <PokemonType, double>{};
    for (final attacker in PokemonType.values) {
      var m = 1.0;
      for (final d in defenders) {
        m *= attacker.attackMultiplier(d);
      }
      map[attacker] = m;
    }
    return TypeMatchup(map);
  }

  double multiplierFrom(PokemonType attacker) => defense[attacker] ?? 1;

  List<MapEntry<PokemonType, double>> get weaknesses =>
      defense.entries.where((e) => e.value > 1).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  List<MapEntry<PokemonType, double>> get resistances =>
      defense.entries.where((e) => e.value > 0 && e.value < 1).toList()
        ..sort((a, b) => a.value.compareTo(b.value));

  List<PokemonType> get immunities =>
      defense.entries.where((e) => e.value == 0).map((e) => e.key).toList();
}

/// 2 -> "×2", 0.5 -> "×½", 0.25 -> "×¼".
String formatMultiplier(double m) {
  if (m == 0.5) return '×½';
  if (m == 0.25) return '×¼';
  return '×${m.toStringAsFixed(0)}';
}
