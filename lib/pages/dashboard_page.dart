import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/explore_controller.dart';
import '../controllers/pokemon_controller.dart';
import '../models/pokemon.dart';
import '../routes/app_routes.dart';
import '../services/pokemon_api_service.dart';
import '../theme/app_colors.dart';
import '../utils/pokemon_utils.dart';
import '../widgets/analysis_widgets.dart';
import '../widgets/loading.dart';
import '../widgets/pokemon_3d_viewer.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/region_sheet.dart';
import '../widgets/type_chip.dart';
import 'detail_page.dart' show InfoCard, StatRow;

/// Dashboard: satu Pokémon 3D besar di tengah. Geser ke kiri/kanan untuk
/// berganti Pokémon; detail (tipe, ukuran, kemampuan, statistik) ikut berubah.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PokemonController _c = Get.find<PokemonController>();
  final ExploreController _explore = Get.find<ExploreController>();
  final PageController _pc = PageController();

  int _index = 0;
  int? _requestedId;
  int? _firstId;
  Pokemon? _detail;
  String? _detailError;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Color get _color {
    final d = _detail;
    return d == null ? AppColors.brand : typeColor(d.types.first);
  }

  void _ensureDetail(int id) {
    if (_requestedId == id) return;
    _requestedId = id;
    _detailError = null;
    _c.detail(id).then((p) {
      if (!mounted || _requestedId != id) return;
      setState(() => _detail = p);
    }).catchError((Object e) {
      if (!mounted || _requestedId != id) return;
      setState(() =>
          _detailError = e is ApiException ? e.message : 'Gagal memuat detail');
    });
  }

  void _onPage(int i) {
    setState(() => _index = i);
    if (i >= _c.items.length - 4) _c.loadMore();
  }

  void _go(int delta, int count) {
    final target = (_index + delta).clamp(0, count - 1);
    _pc.animateToPage(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _random(int count) {
    _pc.animateToPage(
      math.Random().nextInt(count),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_color.withValues(alpha: 0.16), bg],
          stops: const [0, 0.48],
        ),
      ),
      child: Obx(() {
        final items = _c.items.toList();
        Widget body;
        if (_c.loading.value && items.isEmpty) {
          body = const LoadingView();
        } else if (_c.error.value != null && items.isEmpty) {
          body = ErrorView(message: _c.error.value!, onRetry: _c.reload);
        } else if (items.isEmpty) {
          body = const EmptyView(message: 'Pokémon tidak ditemukan');
        } else {
          body = _dashboard(items);
        }
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            titleSpacing: 18,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.24),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.catching_pokemon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 11),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PokéDex',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                    ),
                    Text(
                      'TRAINER FIELD GUIDE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (items.isNotEmpty)
                IconButton.filledTonal(
                  tooltip: 'Acak Pokémon',
                  icon: const Icon(Icons.shuffle),
                  onPressed: () => _random(items.length),
                ),
            ],
          ),
          body: body,
        );
      }),
    );
  }

  void _openRegionSheet() => RegionSheet.show(context);

  /// Chip wilayah aktif (P8/P9) dan Pokémon hari ini.
  Widget _chips() {
    return SizedBox(
      height: 44,
      child: Obx(() {
        final r = _explore.region.value;
        final daily = _explore.dailyPokemon.value;
        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            InputChip(
              avatar: const Icon(Icons.public, size: 18),
              label: Text(r == null
                  ? 'Semua wilayah'
                  : '${r.name} • #${r.startId}–${r.endId}'),
              onPressed: _openRegionSheet,
              onDeleted: r == null ? null : () => _explore.selectRegion(null),
            ),
            const SizedBox(width: 8),
            if (daily != null)
              ActionChip(
                avatar: const Icon(Icons.today, size: 18),
                label: Text('Hari ini: ${daily.name.pretty}'),
                onPressed: () => Get.toNamed(
                  AppRoutes.detail,
                  arguments: daily,
                  preventDuplicates: false,
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _dashboard(List<PokemonSummary> items) {
    // Daftar berubah (mis. filter di tab Jelajah): kembali ke awal.
    if (_firstId != items.first.id) {
      _firstId = items.first.id;
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pc.hasClients) _pc.jumpToPage(0);
      });
    }
    final idx = _index.clamp(0, items.length - 1);
    final cur = items[idx];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureDetail(cur.id);
    });

    final stageHeight =
        math.min(300.0, MediaQuery.of(context).size.height * 0.34);
    final d = _detail?.id == cur.id ? _detail : null;
    final textTheme = Theme.of(context).textTheme;
    final surface = Theme.of(context).colorScheme.surface;

    return Column(
      children: [
        _chips(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
          child: Container(
            height: stageHeight,
            decoration: BoxDecoration(
              color: surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _color.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 10,
                  right: 12,
                  child: Text(
                    formatId(cur.id),
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _color.withValues(alpha: 0.12),
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -76,
                  left: -46,
                  child: Icon(
                    Icons.catching_pokemon,
                    size: 220,
                    color: _color.withValues(alpha: 0.06),
                  ),
                ),
                PageView.builder(
                  controller: _pc,
                  itemCount: items.length,
                  onPageChanged: _onPage,
                  itemBuilder: (_, i) => AnimatedBuilder(
                    animation: _pc,
                    builder: (_, __) {
                      final page = _pc.hasClients && _pc.position.haveDimensions
                          ? (_pc.page ?? _index.toDouble())
                          : _index.toDouble();
                      return Pokemon3DViewer(
                        key: ValueKey(items[i].id),
                        imageUrl: items[i].imageUrl,
                        color: _color,
                        height: stageHeight,
                        swipeMode: true,
                        pageOffset: page - i,
                        active: (page - i).abs() < 1.0,
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 10,
                  child: IconButton.filledTonal(
                    onPressed: idx > 0 ? () => _go(-1, items.length) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                ),
                Positioned(
                  right: 10,
                  child: IconButton.filledTonal(
                    onPressed: idx < items.length - 1
                        ? () => _go(1, items.length)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Row(
            key: ValueKey(cur.id),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WILD POKÉMON',
                    style: textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w800,
                      color: _color,
                    ),
                  ),
                  Text(
                    prettyName(cur.name),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Text(
                formatId(cur.id),
                style: textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Geser untuk berganti Pokémon  ·  ketuk untuk jeda putar',
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _detailPanel(cur, d, textTheme)),
      ],
    );
  }

  Widget _detailPanel(PokemonSummary cur, Pokemon? d, TextTheme textTheme) {
    if (_detailError != null && d == null) {
      return ErrorView(
        message: _detailError!,
        onRetry: () {
          _requestedId = null;
          _ensureDetail(cur.id);
        },
      );
    }
    if (d == null) return const LoadingView();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final t in d.types)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TypeBadge(type: t),
                ),
              const SizedBox(width: 4),
              FavoriteButton(pokemonId: d.id),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InfoCard(
                label: 'Tinggi',
                value: '${d.heightM.toStringAsFixed(1)} m',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoCard(
                label: 'Berat',
                value: '${d.weightKg.toStringAsFixed(1)} kg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PowerSummary(pokemon: d, color: _color),
        const SizedBox(height: 16),
        Text('Kemampuan', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in d.abilities) Chip(label: Text(prettyName(a))),
          ],
        ),
        const SizedBox(height: 16),
        Text('Statistik Dasar', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final s in d.stats) StatRow(stat: s, color: _color),
        const SizedBox(height: 16),
        MatchupSection(pokemon: d),
        _recentStrip(textTheme),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.detail, arguments: cur),
          icon: const Icon(Icons.open_in_full),
          label: const Text('Lihat detail lengkap & putar 3D'),
        ),
      ],
    );
  }

  /// Alur "Terakhir dilihat": diisi saat detail dibuka, disimpan di local storage.
  Widget _recentStrip(TextTheme textTheme) {
    return Obx(() {
      final list = _c.recent.toList();
      if (list.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Terakhir dilihat', style: textTheme.titleMedium),
              ),
              TextButton(onPressed: _c.clearRecent, child: const Text('Hapus')),
            ],
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = list[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Get.toNamed(
                    AppRoutes.detail,
                    arguments: p,
                    preventDuplicates: false,
                  ),
                  child: Container(
                    width: 84,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.catching_pokemon,
                                color: Colors.grey),
                          ),
                        ),
                        Text(
                          p.name.pretty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
