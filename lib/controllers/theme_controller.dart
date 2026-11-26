import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../database/local_database.dart';

/// P9 (GetX) + P7 (Local Storage): mode tema reaktif yang diingat antar sesi.
class ThemeController extends GetxController {
  final LocalDatabase _db = LocalDatabase.instance;
  final Rx<ThemeMode> mode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    mode.value = ThemeMode.values.firstWhere(
      (m) => m.name == _db.themeMode,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    Get.changeThemeMode(m);
    await _db.setThemeMode(m.name);
  }
}
