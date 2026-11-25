import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pokemon_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/loading.dart';
import '../models/pokemon.dart';
import '../utils/pokemon_utils.dart';
import '../widgets/pokemon_3d_carousel.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/type_chip.dart';
import 'favorite_page.dart';
import 'profile_page.dart';

/// Kerangka utama dengan navigation bar: Beranda, Favorit, Profil.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          _BrowseTab(),
          FavoritePage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.catching_pokemon_outlined),
            selectedIcon: Icon(Icons.catching_pokemon),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _BrowseTab extends StatefulWidget {
  const _BrowseTab();

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  final PokemonController _c = Get.find<PokemonController>();
  final GlobalKey<Pokemon3DCarouselState> _carousel = GlobalKey();
  int _current = 0;

  void _onPageChanged(int i) {
    if (!mounted) return;
    setState(() => _current = i);
    // Muat Pokémon berikutnya sebelum pengguna menggeser sampai ujung.
    if (i >= _c.items.length - 4) _c.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.catching_pokemon, color: Colors.red),
            SizedBox(width: 8),
            Text('PokéDex', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: AppSearchBar(
              controller: _c.searchText,
              onChanged: _c.onQueryChanged,
              onSubmitted: _c.submitSearch,
              onClear: _c.clearSearch,
              onHistory: () => Get.toNamed(AppRoutes.history),
            ),
          ),
          SizedBox(
            height: 48,
            child: Obx(() {
              final selected = _c.selectedType.value;
              final types = _c.types.toList();
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  for (final t in types)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TypeChip(
                        type: t,
                        selected: selected == t,
                        onTap: () => _c.setType(t),
                      ),
                    ),
                ],
              );
            }),
          ),
          Expanded(child: Obx(_buildContent)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_c.loading.value && _c.items.isEmpty) return const LoadingView();

    final error = _c.error.value;
    if (error != null && _c.items.isEmpty) {
      return ErrorView(message: error, onRetry: _c.reload);
    }

    if (_c.items.isEmpty) {
      return const EmptyView(message: 'Pokémon tidak ditemukan');
    }

    final loadingMore = _c.loadingMore.value;
    final items = _c.items.toList();
    final index = _current.clamp(0, items.length - 1);
    final p = items[index];
    final accent = pokemonAccent(p.id);
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final h = math.min(340.0, box.maxHeight * 0.48);
          return Column(
            children: [
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Nomor besar sebagai latar.
                  Text(
                    p.id.toString().padLeft(3, '0'),
                    style: TextStyle(
                      fontSize: h * 0.42,
                      fontWeight: FontWeight.w900,
                      color: accent.withValues(alpha: 0.18),
                    ),
                  ),
                  Pokemon3DCarousel(
                    key: _carousel,
                    items: items,
                    height: h,
                    onPageChanged: _onPageChanged,
                    onTap: (s) =>
                        Get.toNamed(AppRoutes.detail, arguments: s),
                  ),
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, size: 32),
                      onPressed: index > 0
                          ? () => _carousel.currentState?.previous()
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, size: 32),
                      onPressed: index < items.length - 1
                          ? () => _carousel.currentState?.next()
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(formatId(p.id),
                  style: textTheme.titleMedium?.copyWith(color: Colors.grey)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    prettyName(p.name),
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  FavoriteButton(pokemonId: p.id),
                ],
              ),
              _TypeRow(pokemon: p),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.detail, arguments: p),
                icon: const Icon(Icons.info_outline),
                label: const Text('Lihat detail'),
              ),
              const SizedBox(height: 8),
              Text(
                '${index + 1} / ${items.length}${_c.hasMore.value ? '+' : ''}'
                '   •   geser untuk ganti Pokémon',
                style: textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              if (loadingMore)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(),
                  ),
                ),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }
}

/// Lencana tipe Pokémon yang tampil (diambil dari detail yang sudah di-cache).
class _TypeRow extends StatelessWidget {
  final PokemonSummary pokemon;

  const _TypeRow({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PokemonController>();
    return SizedBox(
      height: 36,
      child: FutureBuilder<Pokemon>(
        key: ValueKey(pokemon.id),
        future: c.detail(pokemon.id),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final t in snap.data!.types)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TypeBadge(type: t),
                ),
            ],
          );
        },
      ),
    );
  }
}
