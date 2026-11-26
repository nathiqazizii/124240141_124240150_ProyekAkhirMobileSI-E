import '../config.dart';
import 'pokemon_type.dart';

// ---------------------------------------------------------------------------
// P1 (OOP & Dart): kelas abstrak, pewarisan, mixin, enum, getter, interface
// (Comparable), const constructor, factory constructor.
// ---------------------------------------------------------------------------

/// Induk semua model Pokémon: identitas + urutan alami berdasarkan nomor.
abstract class PokemonBase implements Comparable<PokemonBase> {
  const PokemonBase();

  int get id;
  String get name;

  String get imageUrl => AppConfig.artworkUrl(id);

  @override
  int compareTo(PokemonBase other) => id.compareTo(other.id);
}

/// Tingkat kekuatan berdasarkan total base stat.
enum PowerTier {
  s('S', 'Legendaris'),
  a('A', 'Sangat kuat'),
  b('B', 'Kuat'),
  c('C', 'Sedang'),
  d('D', 'Dasar');

  final String letter;
  final String label;
  const PowerTier(this.letter, this.label);

  static PowerTier fromTotal(int total) {
    if (total >= 600) return s;
    if (total >= 500) return a;
    if (total >= 400) return b;
    if (total >= 300) return c;
    return d;
  }
}

/// Mixin analisis kekuatan: dipasang pada kelas yang punya daftar [stats].
mixin PowerAnalysis {
  List<PokemonStat> get stats;

  int get totalPower => stats.fold(0, (sum, s) => sum + s.value);
  PowerTier get tier => PowerTier.fromTotal(totalPower);

  int statValue(String name) {
    for (final s in stats) {
      if (s.name == name) return s.value;
    }
    return 0;
  }
}

/// Data ringkas untuk daftar (id + nama), cukup untuk kartu di grid.
class PokemonSummary extends PokemonBase {
  @override
  final int id;
  @override
  final String name;

  const PokemonSummary({required this.id, required this.name});

  /// Dari item `results` PokéAPI: `{name, url}`; id diambil dari ujung URL.
  factory PokemonSummary.fromListItem(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final segments = url.split('/').where((s) => s.isNotEmpty).toList();
    return PokemonSummary(
      id: int.parse(segments.last),
      name: json['name'] as String,
    );
  }

  factory PokemonSummary.fromJson(Map<String, dynamic> json) =>
      PokemonSummary(id: json['id'] as int, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class PokemonStat {
  final String name;
  final int value;

  const PokemonStat({required this.name, required this.value});

  factory PokemonStat.fromJson(Map<String, dynamic> json) =>
      PokemonStat(name: json['name'] as String, value: json['value'] as int);

  Map<String, dynamic> toJson() => {'name': name, 'value': value};
}

class Pokemon extends PokemonBase with PowerAnalysis {
  @override
  final int id;
  @override
  final String name;
  final List<String> types;

  /// Tinggi dalam desimeter, berat dalam hektogram (satuan asli PokéAPI).
  final int height;
  final int weight;
  final List<String> abilities;
  @override
  final List<PokemonStat> stats;

  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.height,
    required this.weight,
    required this.abilities,
    required this.stats,
  });

  double get heightM => height / 10;
  double get weightKg => weight / 10;

  /// Kelemahan & ketahanan tipe (lihat [TypeMatchup]).
  TypeMatchup get matchup => TypeMatchup.of(types);

  PokemonSummary get summary => PokemonSummary(id: id, name: name);

  /// Dari respons `/pokemon/{id}` PokéAPI.
  factory Pokemon.fromApi(Map<String, dynamic> json) {
    final types = (json['types'] as List<dynamic>)
        .map((t) => (t as Map<String, dynamic>)['type']['name'] as String)
        .toList();
    final abilities = (json['abilities'] as List<dynamic>)
        .map((a) => (a as Map<String, dynamic>)['ability']['name'] as String)
        .toList();
    final stats = (json['stats'] as List<dynamic>).map((s) {
      final m = s as Map<String, dynamic>;
      return PokemonStat(
        name: m['stat']['name'] as String,
        value: m['base_stat'] as int,
      );
    }).toList();

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      types: types,
      height: json['height'] as int,
      weight: json['weight'] as int,
      abilities: abilities,
      stats: stats,
    );
  }

  /// Dari cache lokal (format hasil [toJson]).
  factory Pokemon.fromJson(Map<String, dynamic> json) => Pokemon(
        id: json['id'] as int,
        name: json['name'] as String,
        types: List<String>.from(json['types'] as List<dynamic>),
        height: json['height'] as int,
        weight: json['weight'] as int,
        abilities: List<String>.from(json['abilities'] as List<dynamic>),
        stats: (json['stats'] as List<dynamic>)
            .map((s) => PokemonStat.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'types': types,
        'height': height,
        'weight': weight,
        'abilities': abilities,
        'stats': stats.map((s) => s.toJson()).toList(),
      };
}
