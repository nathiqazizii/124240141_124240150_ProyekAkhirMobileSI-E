import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/favorite_controller.dart';
import '../models/pokemon.dart';
import '../theme/app_colors.dart';
import '../utils/pokemon_utils.dart';
import 'tilt_3d.dart';

/// Tombol hati: tambah/hapus favorit, ikut berubah secara reaktif.
class FavoriteButton extends StatelessWidget {
  final int pokemonId;

  const FavoriteButton({super.key, required this.pokemonId});

  @override
  Widget build(BuildContext context) {
    final fav = Get.find<FavoriteController>();
    return Obx(() {
      final isFav = fav.ids.contains(pokemonId);
      return IconButton(
        tooltip: isFav ? 'Hapus dari favorit' : 'Tambah ke favorit',
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? AppColors.favorite : null,
        ),
        onPressed: () async {
          final error = await fav.toggle(pokemonId);
          if (error != null) {
            Get.snackbar('Gagal', error, snackPosition: SnackPosition.BOTTOM);
          }
        },
      );
    });
  }
}

class PokemonCard extends StatelessWidget {
  final PokemonSummary pokemon;
  final VoidCallback onTap;

  const PokemonCard({super.key, required this.pokemon, required this.onTap});

  /// Warna aksen unik per Pokémon (daftar belum memuat tipe).
  Color get _accent =>
      HSLColor.fromAHSL(1, (pokemon.id * 47) % 360.0, 0.65, 0.6).toColor();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = _accent;

    return Tilt3D(
      builder: (context, tilt) => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shadowColor: accent.withValues(alpha: 0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accent.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.19),
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
              // Kilau yang bergeser mengikuti sentuhan.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(tilt.dx, tilt.dy),
                      radius: 0.9,
                      colors: [
                        Colors.white.withValues(
                          alpha: 0.10 + 0.25 * tilt.distance.clamp(0.0, 1.0),
                        ),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    formatId(pokemon.id),
                    style: textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Bayangan di lantai, bergerak berlawanan dengan gambar.
                          Align(
                            alignment: const Alignment(0, 0.95),
                            child: Transform.translate(
                              offset: Offset(-tilt.dx * 8, 0),
                              child: Container(
                                width: 70,
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.22),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Gambar "timbul": digeser + diperbesar (efek kedalaman).
                          Transform.translate(
                            offset: Offset(tilt.dx * 10, tilt.dy * 10 - 4),
                            child: Transform.scale(
                              scale: 1.08,
                              child: Image.network(
                                pokemon.imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          ),
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.catching_pokemon,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prettyName(pokemon.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: FavoriteButton(pokemonId: pokemon.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
