import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/explore_controller.dart';
import '../controllers/pokemon_controller.dart';
import '../routes/app_routes.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/loading.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/type_chip.dart';
import 'dashboard_page.dart';
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
  void initState() {
    super.initState();
    // P8 + P4: setelah beranda tampil, buka detail bila aplikasi dibuka dari
    // notifikasi, lalu cek notifikasi "Pokémon hari ini".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.openLaunchPayload();
      Get.find<ExploreController>().checkDailyNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          // TickerMode: hentikan animasi 3D saat tab Dashboard tidak aktif.
          TickerMode(enabled: _index == 0, child: const DashboardPage()),
          const _BrowseTab(),
          const FavoritePage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.catching_pokemon_outlined),
            selectedIcon: Icon(Icons.catching_pokemon),
            label: 'Pokédex',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Jelajah',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
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
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        _c.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.catching_pokemon, color: AppColors.brand),
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
          // Wilayah aktif dipilih di Dashboard; daftar ini ikut berubah (GetX).
          Obx(() {
            final r = _c.region.value;
            if (r == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.public, size: 18),
                  label: Text('Wilayah ${r.name} • #${r.startId}–${r.endId}'),
                  onDeleted: () =>
                      Get.find<ExploreController>().selectRegion(null),
                ),
              ),
            );
          }),
          SizedBox(
            height: 48,
            child: Obx(() {
              final selected = _c.selectedType.value;
              final types = _c.types.toList();
              return ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _c.reload,
            child: GridView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 350 + (i % 2) * 120),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * 24),
                    child: child,
                  ),
                ),
                child: PokemonCard(
                  pokemon: items[i],
                  onTap: () =>
                      Get.toNamed(AppRoutes.detail, arguments: items[i]),
                ),
              ),
            ),
          ),
        ),
        if (loadingMore) const LinearProgressIndicator(),
      ],
    );
  }
}
