import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pokemon_controller.dart';
import '../models/pokemon.dart';
import '../models/species.dart';
import '../routes/app_routes.dart';
import '../services/pokemon_api_service.dart';
import '../utils/pokemon_utils.dart';
import 'loading.dart';

/// P6 (HTTP): bagian detail yang dimuat lewat request berantai
/// (species -> rantai evolusi). Punya state loading/error/retry sendiri,
/// jadi kegagalannya tidak mengganggu bagian detail lain.
class SpeciesSection extends StatefulWidget {
  final int pokemonId;

  const SpeciesSection({super.key, required this.pokemonId});

  @override
  State<SpeciesSection> createState() => _SpeciesSectionState();
}

class _SpeciesSectionState extends State<SpeciesSection> {
  final PokemonController _c = Get.find<PokemonController>();
  late Future<PokemonSpecies> _future;

  @override
  void initState() {
    super.initState();
    _future = _c.species(widget.pokemonId);
  }

  void _retry() => setState(() => _future = _c.species(widget.pokemonId));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<PokemonSpecies>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: LoadingView(),
          );
        }
        if (snap.hasError) {
          final e = snap.error;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e is ApiException ? e.message : 'Gagal memuat deskripsi',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(onPressed: _retry, child: const Text('Coba lagi')),
              ],
            ),
          );
        }

        final sp = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deskripsi', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            if (sp.genus.isNotEmpty)
              Text(sp.genus,
                  style: textTheme.labelLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(sp.description.isEmpty ? '-' : sp.description),
            if (sp.evolution.length > 1) ...[
              const SizedBox(height: 20),
              Text('Rantai Evolusi', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var i = 0; i < sp.evolution.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward, color: Colors.grey),
                        ),
                      Column(
                        children: [
                          for (final p in sp.evolution[i])
                            _EvoItem(
                              pokemon: p,
                              current: p.id == widget.pokemonId,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EvoItem extends StatelessWidget {
  final PokemonSummary pokemon;
  final bool current;

  const _EvoItem({required this.pokemon, required this.current});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      // P4 (Navigation): berpindah ke detail evolusi (ditumpuk di atas halaman ini).
      onTap: current
          ? null
          : () => Get.toNamed(
                AppRoutes.detail,
                arguments: pokemon,
                preventDuplicates: false,
              ),
      child: Container(
        width: 96,
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: current ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 72,
              child: Image.network(
                pokemon.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.catching_pokemon, color: Colors.grey),
              ),
            ),
            Text(
              pokemon.name.pretty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(pokemon.id.pokedexNo,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
