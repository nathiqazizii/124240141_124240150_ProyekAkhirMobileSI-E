import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/explore_controller.dart';
import 'controllers/favorite_controller.dart';
import 'controllers/pokemon_controller.dart';
import 'controllers/theme_controller.dart';
import 'database/local_database.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseKey,
  );
  await LocalDatabase.instance.init();
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // Notifikasi opsional; aplikasi tetap berjalan tanpanya.
  }

  // Tema dibaca dari local storage sebelum aplikasi tampil.
  Get.put<ThemeController>(ThemeController(), permanent: true);

  runApp(const PokedexApp());
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<ExploreController>(ExploreController(), permanent: true);
    Get.put<PokemonController>(PokemonController(), permanent: true);
    Get.put<FavoriteController>(FavoriteController(), permanent: true);
  }
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final radius = BorderRadius.circular(16);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkInput : surface,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PokéDex',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: Get.find<ThemeController>().mode.value,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
    );
  }
}

/// Ditampilkan bila aplikasi dibuild tanpa `--dart-define` Supabase.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.settings_suggest, size: 64, color: AppColors.brand),
                SizedBox(height: 16),
                Text(
                  'Konfigurasi Supabase belum diatur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Build aplikasi dengan --dart-define=SUPABASE_URL=... '
                  'dan --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
