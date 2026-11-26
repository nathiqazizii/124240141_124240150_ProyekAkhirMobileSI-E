import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../models/pokemon.dart';
import '../models/region.dart';
import '../routes/app_routes.dart';
import '../utils/pokemon_utils.dart';

/// P8 (Notification): notifikasi lokal yang ikut berperan dalam alur aplikasi.
///  - Pengingat harian (berulang).
///  - "Pokémon hari ini": muncul saat aplikasi dibuka pertama kali tiap hari.
///  - Sambutan wilayah: muncul setelah lokasi GPS menentukan wilayah terdekat.
/// Ketuk notifikasi -> membuka halaman detail Pokémon (alur Navigation).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _reminderId = 1;
  static const int _testId = 2;
  static const int _dailyId = 3;
  static const int _regionId = 4;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Payload dari notifikasi yang membuka aplikasi saat proses mati.
  String? _launchPayload;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Pengingat Harian',
      channelDescription: 'Pengingat dan info Pokémon',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (r) => openPayload(r.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchPayload = launch!.notificationResponse?.payload;
    }
  }

  /// Dipanggil sekali setelah halaman utama tampil (cold start dari notifikasi).
  void openLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    openPayload(p);
  }

  /// Payload `pokemon|id|nama` -> buka detail Pokémon.
  static void openPayload(String? payload) {
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.length < 3 || parts[0] != 'pokemon') return;
    final id = int.tryParse(parts[1]);
    if (id == null) return;
    Get.toNamed(
      AppRoutes.detail,
      arguments: PokemonSummary(id: id, name: parts.sublist(2).join('|')),
      preventDuplicates: false,
    );
  }

  static String _payload(PokemonBase p) => 'pokemon|${p.id}|${p.name}';

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> enableDailyReminder() async {
    await _plugin.periodicallyShow(
      _reminderId,
      'PokéDex',
      'Yuk jelajahi Pokémon baru hari ini!',
      RepeatInterval.daily,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> disableDailyReminder() => _plugin.cancel(_reminderId);

  /// Menampilkan notifikasi sekarang juga, untuk mencoba fitur.
  Future<void> showNow() async {
    await _plugin.show(
      _testId,
      'PokéDex',
      'Notifikasi berhasil! Selamat menjelajah Pokémon.',
      _details,
    );
  }

  Future<void> showPokemonOfTheDay(PokemonBase p) async {
    await _plugin.show(
      _dailyId,
      'Pokémon hari ini',
      '${p.id.pokedexNo} ${p.name.pretty} menunggumu. Ketuk untuk melihat!',
      _details,
      payload: _payload(p),
    );
  }

  Future<void> showRegionWelcome(
    Region region,
    PokemonBase firstPokemon, {
    double? distanceKm,
  }) async {
    final near = distanceKm == null
        ? ''
        : ' (±${distanceKm.round()} km dari padanan ${region.analog})';
    await _plugin.show(
      _regionId,
      'Selamat datang di wilayah ${region.name}!$near',
      'Pokémon pertama di sini: ${firstPokemon.name.pretty}. Ketuk untuk melihat.',
      _details,
      payload: _payload(firstPokemon),
    );
  }
}
