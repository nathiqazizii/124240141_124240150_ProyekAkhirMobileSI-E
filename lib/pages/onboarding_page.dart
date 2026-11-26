import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../database/local_database.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// P2 (Widget): PageView, AnimatedContainer, AnimatedSwitcher, Stack.
/// Alur: Splash -> (pertama kali saja) Onboarding -> Login.
/// Status "sudah dilihat" disimpan di local storage (P7).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Slide(this.icon, this.title, this.body, this.color);
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slides = [
    _Slide(
      Icons.view_in_ar,
      'Pokémon dalam 3D',
      'Geser Pokémon di dashboard untuk berganti, lihat detail dan statistiknya.',
      AppColors.brand,
    ),
    _Slide(
      Icons.travel_explore,
      'Jelajahi Wilayah',
      'Pakai lokasimu untuk menemukan wilayah Pokémon terdekat, lengkap dengan notifikasi.',
      AppColors.onboardingExplore,
    ),
    _Slide(
      Icons.favorite,
      'Favorit & Bandingkan',
      'Simpan favoritmu ke akun, lalu adu statistik dua Pokémon.',
      AppColors.onboardingFavorites,
    ),
  ];

  final PageController _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await LocalDatabase.instance.setOnboardingDone();
    Get.offAllNamed(AppRoutes.login);
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _pc.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(last ? '' : 'Lewati'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.color.withValues(alpha: 0.15),
                          ),
                          child: Icon(s.icon, size: 84, color: s.color),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(s.body, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _page
                          ? _slides[_page].color
                          : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(last ? 'Mulai' : 'Lanjut', key: ValueKey(last)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
