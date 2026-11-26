import 'pokemon.dart';

/// Data tambahan dari dua endpoint PokéAPI: `/pokemon-species/{id}`
/// (deskripsi, kategori) dan `/evolution-chain/{id}` (rantai evolusi).
class PokemonSpecies {
  final String genus;
  final String description;

  /// Rantai evolusi per tahap: [[Charmander], [Charmeleon], [Charizard]].
  /// Tahap bercabang (mis. Eevee) berisi beberapa Pokémon.
  final List<List<PokemonSummary>> evolution;

  const PokemonSpecies({
    required this.genus,
    required this.description,
    required this.evolution,
  });

  factory PokemonSpecies.fromApi(
    Map<String, dynamic> species,
    Map<String, dynamic> chain,
  ) {
    String pick(List<dynamic> entries, String key) {
      for (final e in entries) {
        final m = e as Map<String, dynamic>;
        if ((m['language'] as Map<String, dynamic>)['name'] == 'en') {
          return (m[key] as String).replaceAll(RegExp(r'[\n\f]+'), ' ');
        }
      }
      return '';
    }

    final levels = <List<PokemonSummary>>[];
    var current = <Map<String, dynamic>>[chain['chain'] as Map<String, dynamic>];
    while (current.isNotEmpty) {
      levels.add([
        for (final n in current)
          PokemonSummary.fromListItem(n['species'] as Map<String, dynamic>),
      ].where((p) => p.id < 10000).toList());
      current = [
        for (final n in current)
          ...(n['evolves_to'] as List<dynamic>).cast<Map<String, dynamic>>(),
      ];
    }

    return PokemonSpecies(
      genus: pick(species['genera'] as List<dynamic>, 'genus'),
      description:
          pick(species['flavor_text_entries'] as List<dynamic>, 'flavor_text'),
      evolution: levels,
    );
  }

  factory PokemonSpecies.fromJson(Map<String, dynamic> json) => PokemonSpecies(
        genus: json['genus'] as String,
        description: json['description'] as String,
        evolution: (json['evolution'] as List<dynamic>)
            .map((lvl) => (lvl as List<dynamic>)
                .map((p) => PokemonSummary.fromJson(p as Map<String, dynamic>))
                .toList())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'genus': genus,
        'description': description,
        'evolution': [
          for (final lvl in evolution) [for (final p in lvl) p.toJson()],
        ],
      };
}
