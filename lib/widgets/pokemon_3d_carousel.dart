import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import 'pokemon_3d_viewer.dart';

/// Warna aksen unik per Pokémon (daftar belum memuat tipe).
Color pokemonAccent(int id) =>
    HSLColor.fromAHSL(1, (id * 47) % 360.0, 0.65, 0.6).toColor();

/// Carousel Pokémon 3D "berisi" (bukan kartu).
///
/// Geser Pokémon ke kiri/kanan untuk mengganti Pokémon. Pokémon di tengah
/// berputar sendiri; yang di samping mengecil, memudar, dan menoleh ke tengah.
/// Seret ke atas/bawah untuk memiringkan, ketuk untuk membuka detail.
class Pokemon3DCarousel extends StatefulWidget {
  final List<PokemonSummary> items;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PokemonSummary> onTap;
  final double height;

  const Pokemon3DCarousel({
    super.key,
    required this.items,
    required this.onPageChanged,
    required this.onTap,
    this.height = 320,
  });

  @override
  State<Pokemon3DCarousel> createState() => Pokemon3DCarouselState();
}

class Pokemon3DCarouselState extends State<Pokemon3DCarousel> {
  late final PageController _page = PageController(viewportFraction: 0.72);
  int _current = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void next() => _go(_current + 1);
  void previous() => _go(_current - 1);

  void _go(int i) {
    if (i < 0 || i >= widget.items.length) return;
    _page.animateToPage(
      i,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant Pokemon3DCarousel old) {
    super.didUpdateWidget(old);
    // Daftar diganti total (cari / filter / refresh): kembali ke awal.
    final replaced = old.items.isEmpty ||
        widget.items.isEmpty ||
        old.items.first.id != widget.items.first.id;
    if (replaced && _page.hasClients) {
      _current = 0;
      _page.jumpToPage(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPageChanged(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _page,
        itemCount: widget.items.length,
        clipBehavior: Clip.none,
        onPageChanged: (i) {
          setState(() => _current = i);
          widget.onPageChanged(i);
        },
        itemBuilder: (context, i) {
          final p = widget.items[i];
          return AnimatedBuilder(
            animation: _page,
            builder: (context, child) {
              double delta = i - _current.toDouble();
              if (_page.hasClients && _page.position.haveDimensions) {
                delta = i - (_page.page ?? _current.toDouble());
              }
              final d = delta.clamp(-1.5, 1.5);
              final abs = d.abs();
              return Opacity(
                opacity: (1 - abs * 0.55).clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..translate(d * -18.0, 0.0, 0.0)
                    ..rotateY(-d * 0.7)
                    ..scale(1 - math.min(abs, 1.0) * 0.28),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (i == _current) {
                  widget.onTap(p);
                } else {
                  _go(i);
                }
              },
              child: Pokemon3DViewer(
                imageUrl: p.imageUrl,
                color: pokemonAccent(p.id),
                height: widget.height,
                interactive: false,
                showHint: false,
                layers: 10,
                // Hanya Pokémon di tengah yang dianimasikan.
                active: (i - _current).abs() <= 0,
              ),
            ),
          );
        },
      ),
    );
  }
}
