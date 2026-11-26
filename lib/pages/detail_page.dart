import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pokemon_controller.dart';
import '../models/pokemon.dart';
import '../routes/app_routes.dart';
import '../services/pokemon_api_service.dart';
import '../utils/pokemon_utils.dart';
import '../widgets/analysis_widgets.dart';
import '../widgets/loading.dart';
import '../widgets/pokemon_3d_viewer.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/species_section.dart';
import '../widgets/type_chip.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final PokemonController _c = Get.find<PokemonController>();
  late final PokemonSummary _summary;
  late Future<Pokemon> _future;

  @override
  void initState() {
    super.initState();
    _summary = Get.arguments as PokemonSummary;
    _future = _c.detail(_summary.id);
    // Alur "terakhir dilihat": dicatat ke local storage (P7).
    _c.markViewed(_summary);
  }

  void _retry() => setState(() => _future = _c.detail(_summary.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(prettyName(_summary.name)),
        actions: [FavoriteButton(pokemonId: _summary.id)],
      ),
      body: FutureBuilder<Pokemon>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            final e = snapshot.error;
            return ErrorView(
              message: e is ApiException ? e.message : 'Gagal memuat detail',
              onRetry: _retry,
            );
          }
          return _DetailBody(pokemon: snapshot.data!);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Pokemon pokemon;

  const _DetailBody({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mainColor = typeColor(pokemon.types.first);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            height: 272,
            decoration: BoxDecoration(
              color: mainColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: mainColor.withValues(alpha: 0.18)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -34,
                  bottom: -48,
                  child: Icon(
                    Icons.catching_pokemon,
                    size: 220,
                    color: mainColor.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formatId(pokemon.id),
                      style: textTheme.labelLarge?.copyWith(
                        color: mainColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Pokemon3DViewer(
                    imageUrl: pokemon.imageUrl,
                    color: mainColor,
                    height: 260,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(
            children: [
              Text(
                prettyName(pokemon.name),
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [for (final t in pokemon.types) TypeBadge(type: t)],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      label: 'Tinggi',
                      value: '${pokemon.heightM.toStringAsFixed(1)} m',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      label: 'Berat',
                      value: '${pokemon.weightKg.toStringAsFixed(1)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Kemampuan', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in pokemon.abilities)
                    Chip(label: Text(prettyName(a))),
                ],
              ),
              const SizedBox(height: 20),
              Text('Statistik Dasar', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final s in pokemon.stats) StatRow(stat: s, color: mainColor),
              const SizedBox(height: 20),
              PowerSummary(pokemon: pokemon, color: mainColor),
              const SizedBox(height: 20),
              MatchupSection(pokemon: pokemon),
              const SizedBox(height: 10),
              // Deskripsi & evolusi dimuat terpisah (request berantai, P6).
              SpeciesSection(pokemonId: pokemon.id),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    Get.toNamed(AppRoutes.compare, arguments: pokemon),
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Bandingkan dengan Pokémon lain'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const InfoCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final PokemonStat stat;
  final Color color;

  const StatRow({super.key, required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    // 255 adalah nilai dasar tertinggi yang mungkin pada satu statistik.
    final fraction = math.min(stat.value / 255, 1.0);
    const segmentCount = 18;
    final trackColor = Theme.of(context).colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Semantics(
        label: '${statLabel(stat.name)}: ${stat.value} dari 255',
        child: ExcludeSemantics(
          child: Row(
            children: [
              SizedBox(
                width: 126,
                child: Text(
                  statLabel(stat.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${stat.value}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => Row(
                    children: [
                      for (var i = 0; i < segmentCount; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: SizedBox(
                              height: 4,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                    color: trackColor.withValues(alpha: 0.45),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: (progress * segmentCount - i)
                                          .clamp(0.0, 1.0),
                                      child: ColoredBox(color: color),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
