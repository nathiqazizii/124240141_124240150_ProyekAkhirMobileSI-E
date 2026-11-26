import 'package:get/get.dart';

import '../database/local_database.dart';
import '../models/pokemon.dart';
import '../models/region.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/pokemon_api_service.dart';
import 'pokemon_controller.dart';

/// P9 (GetX) + P8 (Lokasi & Notifikasi): satu controller untuk alur
/// "Jelajah Wilayah". State-nya (wilayah aktif, status GPS, Pokémon harian)
/// dipakai bersamaan oleh Dashboard, Jelajah, dan Profil lewat Obx.
///
/// Alur: tombol GPS -> izin & koordinat -> wilayah terdekat -> daftar Pokémon
/// di PokemonController difilter -> notifikasi sambutan -> ketuk -> detail.
class ExploreController extends GetxController {
  final LocalDatabase _db = LocalDatabase.instance;

  final Rxn<Region> region = Rxn<Region>();
  final RxnDouble distanceKm = RxnDouble();
  final RxnString coordinates = RxnString();
  final RxBool locating = false.obs;
  final Rxn<PokemonSummary> dailyPokemon = Rxn<PokemonSummary>();

  PokemonController get _pokemon => Get.find<PokemonController>();

  @override
  void onInit() {
    super.onInit();
    // Pulihkan wilayah terakhir (local storage), lalu siapkan Pokémon harian.
    // (PokemonController memulihkan filter daftarnya sendiri dari sumber yang sama.)
    region.value = Region.byName(_db.lastRegion);
    _prepareDaily();
  }

  /// Id Pokémon hari ini: tetap sama sepanjang hari, berganti tiap hari.
  int get dailyId {
    final n = DateTime.now();
    return ((n.year * 372 + n.month * 31 + n.day) * 7919) % 1025 + 1;
  }

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  Future<void> _prepareDaily() async {
    try {
      final p = await PokemonApiService.instance.fetchDetail(dailyId);
      dailyPokemon.value = p.summary;
    } catch (_) {
      // Offline: kartu "Hari ini" tidak ditampilkan.
    }
  }

  /// Dipanggil saat beranda tampil: bila fitur aktif dan belum ada notifikasi
  /// hari ini, tampilkan notifikasi Pokémon hari ini (sekali per hari).
  Future<void> checkDailyNotification() async {
    if (!_db.dailyPokemonEnabled || _db.lastDailyDate == _today) return;
    final p = dailyPokemon.value ?? await _waitDaily();
    if (p == null) return;
    await NotificationService.instance.showPokemonOfTheDay(p);
    await _db.setLastDailyDate(_today);
  }

  Future<PokemonSummary?> _waitDaily() async {
    await _prepareDaily();
    return dailyPokemon.value;
  }

  /// GPS -> wilayah terdekat -> terapkan. Mengembalikan pesan error atau null.
  Future<String?> exploreNearest() async {
    locating.value = true;
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      coordinates.value =
          'Lat ${pos.latitude.toStringAsFixed(4)}, Lng ${pos.longitude.toStringAsFixed(4)}';
      final (r, km) = Region.nearest(pos.latitude, pos.longitude);
      await selectRegion(r, distanceKm: km, notify: true);
      return null;
    } on LocationException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal mengambil lokasi';
    } finally {
      locating.value = false;
    }
  }

  Future<void> selectRegion(
    Region? r, {
    double? distanceKm,
    bool notify = false,
  }) async {
    region.value = r;
    this.distanceKm.value = distanceKm;
    await _db.setLastRegion(r?.name);
    await _pokemon.setRegion(r);

    if (notify && r != null && _pokemon.items.isNotEmpty) {
      final granted = await NotificationService.instance.requestPermission();
      if (granted) {
        await NotificationService.instance.showRegionWelcome(
          r,
          _pokemon.items.first,
          distanceKm: distanceKm,
        );
      }
    }
  }
}
