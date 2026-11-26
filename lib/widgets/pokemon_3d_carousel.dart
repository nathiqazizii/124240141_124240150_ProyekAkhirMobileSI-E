import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../theme/app_colors.dart';
import '../utils/pokemon_utils.dart';
import 'pokemon_3d_viewer.dart';

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
  void didUpdateWidget(covariant Pokemon3DCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Daftar diganti total (cari / filter / refresh): kembali ke awal.
    final replaced = oldWidget.items.isEmpty ||
        widget.items.isEmpty ||
        oldWidget.items.first.id != widget.items.first.id;
    if (replaced || _current >= widget.items.length) {
      _current = 0;
      if (widget.items.isNotEmpty) {
        if (_page.hasClients) _page.jumpToPage(0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onPageChanged(0);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return SizedBox(height: widget.height);

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
                    ..translateByDouble(d * -18.0, 0.0, 0.0, 1.0)
                    ..rotateY(-d * 0.7)
                    ..scaleByDouble(
                      1 - math.min(abs, 1.0) * 0.28,
                      1 - math.min(abs, 1.0) * 0.28,
                      1 - math.min(abs, 1.0) * 0.28,
                      1,
                    ),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Semantics(
                button: true,
                label: '${prettyName(p.name)}, ${formatId(p.id)}',
                hint: i == _current
                    ? 'Ketuk untuk melihat detail'
                    : 'Geser ke Pokémon ini, atau ketuk untuk memilih',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i == _current) {
                      widget.onTap(p);
                    } else {
                      _go(i);
                    }
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.carouselAccent(p.id)
                            .withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.carouselAccent(p.id)
                              .withValues(alpha: 0.10),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.carouselAccent(p.id)
                              .withValues(alpha: 0.14),
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -34,
                            top: 52,
                            child: Icon(
                              Icons.catching_pokemon,
                              size: 170,
                              color: AppColors.carouselAccent(p.id)
                                  .withValues(alpha: 0.055),
                            ),
                          ),
                          Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    IgnorePointer(
                                      child: Pokemon3DViewer(
                                        imageUrl: p.imageUrl,
                                        color: AppColors.carouselAccent(p.id),
                                        height: math.max(
                                          0,
                                          widget.height - 72,
                                        ),
                                        swipeMode: true,
                                        pageOffset: (_current - i).toDouble(),
                                        active: i == _current,
                                      ),
                                    ),
                                    Positioned(
                                      top: 14,
                                      left: 14,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withValues(alpha: 0.84),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          formatId(p.id),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: AppColors.carouselAccent(
                                                    p.id),
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        prettyName(p.name),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(i + 1).toString().padLeft(2, '0')} / ${widget.items.length.toString().padLeft(2, '0')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
