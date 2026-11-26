import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../theme/app_colors.dart';

Color typeColor(String type) => AppColors.pokemonTypes[type] ?? Colors.grey;

const Map<String, String> _statLabels = {
  'hp': 'HP',
  'attack': 'Serangan',
  'defense': 'Pertahanan',
  'special-attack': 'Serangan Khusus',
  'special-defense': 'Pertahanan Khusus',
  'speed': 'Kecepatan',
};

String statLabel(String name) => _statLabels[name] ?? prettyName(name);

/// "mr-mime" -> "Mr Mime"
String prettyName(String raw) => raw
    .split('-')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// 25 -> "#0025"
String formatId(int id) => '#${id.toString().padLeft(4, '0')}';

/// Warna lencana tier kekuatan.
Color tierColor(PowerTier tier) => switch (tier) {
      PowerTier.s => AppColors.tierS,
      PowerTier.a => AppColors.tierA,
      PowerTier.b => AppColors.tierB,
      PowerTier.c => AppColors.tierC,
      PowerTier.d => AppColors.tierD,
    };

// Extension method (P1): menambah kemampuan pada tipe bawaan Dart.
extension PokemonStringX on String {
  String get pretty => prettyName(this);
}

extension PokemonIntX on int {
  String get pokedexNo => formatId(this);
}
