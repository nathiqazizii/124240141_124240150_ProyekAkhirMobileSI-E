import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/local_database.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// P4 (Navigation): gerbang alur awal.
/// Sudah login -> Beranda; belum login & pertama kali -> Onboarding; selain itu -> Login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final firstRun = !LocalDatabase.instance.onboardingDone;
      Get.offAllNamed(loggedIn
          ? AppRoutes.home
          : (firstRun ? AppRoutes.onboarding : AppRoutes.login));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.catching_pokemon, size: 96, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'PokéDex',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
