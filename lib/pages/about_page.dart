import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.catching_pokemon, size: 72, color: AppColors.brand),
          const SizedBox(height: 8),
          Text('PokéDex',
              textAlign: TextAlign.center, style: textTheme.headlineMedium),
          const Text('Versi 1.0.0', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Text(
            'Ensiklopedia Pokémon yang mengambil data dari PokéAPI, dengan '
            'autentikasi dan penyimpanan favorit per pengguna di Supabase.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Proyek Akhir Praktikum Pemrograman Mobile (Flutter).',
          ),
          const SizedBox(height: 24),
          Text('Teknologi', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Flutter • Dart • GetX • http • supabase_flutter • '
            'shared_preferences • flutter_local_notifications • geolocator',
          ),
          const SizedBox(height: 24),
          Text('Alur per Materi Praktikum', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          const _FlowTile('P1 OOP & Dart',
              'Analisis Pokémon: tier & kelemahan tipe dari model OOP'),
          const _FlowTile('P2 Widget',
              'Onboarding + widget yang dipakai ulang di semua alur'),
          const _FlowTile('P3 State & Data',
              'Bandingkan Pokémon dengan setState dan data antar halaman'),
          const _FlowTile('P4 Navigation',
              'Route guard, argumen, tumpukan detail, buka dari notifikasi'),
          const _FlowTile('P6 HTTP',
              'Detail berantai: species lalu evolusi, paging, filter wilayah'),
          const _FlowTile('P7 Local Storage',
              'Cache, terakhir dilihat, tema, wilayah terakhir'),
          const _FlowTile('P8 Notifikasi & Lokasi',
              'GPS lalu wilayah terdekat lalu notifikasi lalu detail'),
          const _FlowTile('P9 GetX',
              'Satu state wilayah menggerakkan Dashboard, Jelajah, dan Profil'),
          const SizedBox(height: 24),
          Text('Sumber & Atribusi', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Data: PokéAPI (pokeapi.co)'),
          const Text('Backend: Supabase (supabase.com)'),
          const SizedBox(height: 12),
          Text(
            'Pokémon dan nama karakter terkait adalah merek dagang Nintendo / '
            'Game Freak / The Pokémon Company. Aplikasi ini dibuat untuk '
            'tujuan pembelajaran.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FlowTile extends StatelessWidget {
  final String title;
  final String body;

  const _FlowTile(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: body),
          ],
        ),
      ),
    );
  }
}
