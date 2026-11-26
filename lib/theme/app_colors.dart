import 'package:flutter/material.dart';

/// Warna aplikasi dikelompokkan di sini agar mudah dicari dan disesuaikan.
class AppColors {
  AppColors._();

  // Warna identitas dan status.
  static const brand = Color(0xFFE94B55);
  static const danger = Colors.red;
  static const favorite = Colors.red;
  static const trophy = Colors.amber;

  // Latar dan permukaan tema.
  static const lightBackground = Color(0xFFF7F5EF);
  static const darkBackground = Color(0xFF17191F);
  static const lightSurface = Color(0xFFFFFEFA);
  static const darkSurface = Color(0xFF20232B);
  static const darkInput = Color(0xFF242832);

  // Aksen carousel: ubah parameter ini untuk menggeser palet warna Pokémon.
  static const carouselHueStep = 47.0;
  // 0 = merah, 60 = kuning. Hue ini menggeser warna seluruh carousel.
  static const carouselHueStart = 0.0;
  static const carouselSaturation = 0.65;
  static const carouselLightness = 0.6;

  static Color carouselAccent(int pokemonId) => HSLColor.fromAHSL(
        1,
        (pokemonId * carouselHueStep + carouselHueStart) % 360.0,
        carouselSaturation,
        carouselLightness,
      ).toColor();

  // Warna tipe Pokémon.
  static const Map<String, Color> pokemonTypes = {
    'normal': Color(0xFFA8A878),
    'fire': Color(0xFFF08030),
    'water': Color(0xFF6890F0),
    'electric': Color(0xFFF8D030),
    'grass': Color(0xFF78C850),
    'ice': Color(0xFF98D8D8),
    'fighting': Color(0xFFC03028),
    'poison': Color(0xFFA040A0),
    'ground': Color(0xFFE0C068),
    'flying': Color(0xFFA890F0),
    'psychic': Color(0xFFF85888),
    'bug': Color(0xFFA8B820),
    'rock': Color(0xFFB8A038),
    'ghost': Color(0xFF705898),
    'dragon': Color(0xFF7038F8),
    'dark': Color(0xFF705848),
    'steel': Color(0xFFB8B8D0),
    'fairy': Color(0xFFEE99AC),
  };

  // Warna kartu onboarding.
  static const onboardingExplore = Color(0xFF42A5F5);
  static const onboardingFavorites = Color(0xFFEC407A);

  // Warna tier kekuatan.
  static const tierS = Color(0xFFFFB300);
  static const tierA = Color(0xFFEF5350);
  static const tierB = Color(0xFF7E57C2);
  static const tierC = Color(0xFF42A5F5);
  static const tierD = Color(0xFF9E9E9E);
}
