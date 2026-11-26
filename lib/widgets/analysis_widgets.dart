import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../models/pokemon_type.dart';
import '../utils/pokemon_utils.dart';

/// P2 (Widget) + P1 (OOP): kartu ringkasan kekuatan, memakai mixin
/// [PowerAnalysis] pada model [Pokemon].
class PowerSummary extends StatelessWidget {
  final Pokemon pokemon;
  final Color color;

  const PowerSummary({super.key, required this.pokemon, required this.color});

  @override
  Widget build(BuildContext context) {
    final tier = pokemon.tier;
    final tc = tierColor(tier);
    final fraction = (pokemon.totalPower / 780).clamp(0.0, 1.0);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: tc,
              child: Text(
                tier.letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tier ${tier.letter} • ${tier.label}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text('Total kekuatan dasar: ${pokemon.totalPower}'),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        color: tc,
                        backgroundColor: tc.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kelemahan, ketahanan, dan kekebalan tipe (hasil [TypeMatchup]).
class MatchupSection extends StatelessWidget {
  final Pokemon pokemon;

  const MatchupSection({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final m = pokemon.matchup;
    final textTheme = Theme.of(context).textTheme;

    Widget group(String title, List<Widget> chips) {
      if (chips.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Efektivitas Tipe', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        group('Lemah terhadap', [
          for (final e in m.weaknesses) _MultChip(type: e.key, mult: e.value),
        ]),
        group('Tahan terhadap', [
          for (final e in m.resistances) _MultChip(type: e.key, mult: e.value),
        ]),
        group('Kebal terhadap', [
          for (final t in m.immunities) _MultChip(type: t, mult: 0),
        ]),
      ],
    );
  }
}

class _MultChip extends StatelessWidget {
  final PokemonType type;
  final double mult;

  const _MultChip({required this.type, required this.mult});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: typeColor(type.name),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${type.label} ${formatMultiplier(mult)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
