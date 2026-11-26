import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pokemon_controller.dart';
import '../models/pokemon.dart';
import '../models/pokemon_type.dart';
import '../services/pokemon_api_service.dart';
import '../theme/app_colors.dart';
import '../utils/pokemon_utils.dart';
import '../widgets/loading.dart';

/// P3 (State & Data): halaman StatefulWidget yang memakai setState murni.
/// Data Pokémon A dikirim lewat argumen navigasi (P4); Pokémon B dipilih
/// pengguna lewat bottom sheet dan di-fetch (P6). Hasilnya dihitung dengan
/// model OOP (P1): total kekuatan, tier, dan keunggulan tipe.
class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final PokemonController _c = Get.find<PokemonController>();
  late final Pokemon _a;
  Pokemon? _b;
  bool _loadingB = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _a = Get.arguments as Pokemon;
  }

  Future<void> _pick() async {
    final chosen = await Get.bottomSheet<PokemonSummary>(
      _PickerSheet(controller: _c, excludeId: _a.id),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
    if (chosen == null) return;

    setState(() {
      _loadingB = true;
      _error = null;
    });
    try {
      final b = await _c.detail(chosen.id);
      if (mounted) setState(() => _b = b);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e is ApiException ? e.message : 'Gagal memuat Pokémon');
      }
    } finally {
      if (mounted) setState(() => _loadingB = false);
    }
  }

  /// Pengali terbaik serangan [from] terhadap [to] memakai tipe-tipenya.
  double _typeAdvantage(Pokemon from, Pokemon to) {
    var best = 0.0;
    for (final t in from.types) {
      final type = PokemonType.tryParse(t);
      if (type == null) continue;
      final m = to.matchup.multiplierFrom(type);
      if (m > best) best = m;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    return Scaffold(
      appBar: AppBar(title: const Text('Bandingkan Pokémon')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _Side(pokemon: _a)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('VS',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: _loadingB
                    ? const SizedBox(height: 180, child: LoadingView())
                    : b == null
                        ? _EmptySide(onTap: _pick)
                        : _Side(pokemon: b, onChange: _pick),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          if (b != null) ...[
            const SizedBox(height: 20),
            _verdict(b),
            const SizedBox(height: 20),
            Text('Statistik', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final s in _a.stats)
              _CompareRow(
                label: statLabel(s.name),
                a: s.value,
                b: b.statValue(s.name),
              ),
            _CompareRow(label: 'Total', a: _a.totalPower, b: b.totalPower),
          ],
        ],
      ),
    );
  }

  Widget _verdict(Pokemon b) {
    final diff = _a.totalPower - b.totalPower;
    final advA = _typeAdvantage(_a, b);
    final advB = _typeAdvantage(b, _a);

    final String power = diff == 0
        ? 'Total kekuatan seimbang (${_a.totalPower})'
        : '${(diff > 0 ? _a : b).name.pretty} unggul ${diff.abs()} poin total kekuatan';
    final String type = advA == advB
        ? 'Keunggulan tipe seimbang'
        : '${(advA > advB ? _a : b).name.pretty} unggul tipe '
            '(${formatMultiplier(advA > advB ? advA : advB)})';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.emoji_events, color: AppColors.trophy),
              const SizedBox(width: 8),
              Text('Hasil', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            Text('• $power'),
            Text('• $type'),
          ],
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback? onChange;

  const _Side({required this.pokemon, this.onChange});

  @override
  Widget build(BuildContext context) {
    final tc = tierColor(pokemon.tier);
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: Image.network(
            pokemon.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.catching_pokemon,
                size: 64, color: Colors.grey),
          ),
        ),
        Text(pokemon.id.pokedexNo, style: const TextStyle(color: Colors.grey)),
        Text(
          pokemon.name.pretty,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: tc,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Tier ${pokemon.tier.letter}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
        if (onChange != null)
          TextButton(onPressed: onChange, child: const Text('Ganti')),
      ],
    );
  }
}

class _EmptySide extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptySide({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.6)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 40),
            SizedBox(height: 8),
            Text('Pilih Pokémon', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final int a;
  final int b;

  const _CompareRow({required this.label, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxV = (a > b ? a : b).clamp(1, 1 << 30);

    Widget bar(int v, bool win, {required bool alignEnd}) {
      return Expanded(
        child: Align(
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: v / maxV),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, f, __) => FractionallySizedBox(
              widthFactor: f.clamp(0.02, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: win ? scheme.primary : scheme.outline,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('$a',
                    style: TextStyle(
                        fontWeight:
                            a >= b ? FontWeight.w800 : FontWeight.w400)),
              ),
              bar(a, a >= b, alignEnd: true),
              const SizedBox(width: 8),
              bar(b, b >= a, alignEnd: false),
              SizedBox(
                width: 36,
                child: Text('$b',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight:
                            b >= a ? FontWeight.w800 : FontWeight.w400)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet pencarian Pokémon pembanding (state lokal lewat StatefulBuilder).
class _PickerSheet extends StatefulWidget {
  final PokemonController controller;
  final int excludeId;

  const _PickerSheet({required this.controller, required this.excludeId});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late final Future<List<PokemonSummary>> _names =
      widget.controller.ensureNames().catchError((_) => <PokemonSummary>[]);
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama atau nomor Pokémon',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PokemonSummary>>(
              future: _names,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                final all = (snap.data ?? const <PokemonSummary>[])
                    .where((p) => p.id != widget.excludeId)
                    .where((p) =>
                        _q.isEmpty ||
                        p.name.contains(_q) ||
                        p.id.toString() == _q)
                    .take(60)
                    .toList();
                if (all.isEmpty) {
                  return const EmptyView(message: 'Pokémon tidak ditemukan');
                }
                return ListView.builder(
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final p = all[i];
                    return ListTile(
                      leading: SizedBox(
                        width: 44,
                        child: Image.network(
                          p.imageUrl,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.catching_pokemon,
                              color: Colors.grey),
                        ),
                      ),
                      title: Text(p.name.pretty),
                      subtitle: Text(p.id.pokedexNo),
                      onTap: () => Get.back(result: p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
