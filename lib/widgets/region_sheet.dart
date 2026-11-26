import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/explore_controller.dart';
import '../models/region.dart';

/// P8 (Lokasi): pilih wilayah lewat GPS (wilayah terdekat) atau manual.
/// Semua state ada di [ExploreController] (P9), jadi Dashboard, Jelajah, dan
/// Profil langsung ikut berubah begitu wilayah dipilih.
class RegionSheet extends StatelessWidget {
  const RegionSheet({super.key});

  static void show(BuildContext context) {
    Get.bottomSheet(
      const RegionSheet(),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = Get.find<ExploreController>();
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Jelajah Wilayah', style: textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() {
                final r = e.region.value;
                final km = e.distanceKm.value;
                final coords = e.coordinates.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: e.locating.value
                            ? null
                            : () async {
                                final err = await e.exploreNearest();
                                if (err != null) {
                                  Get.snackbar('Lokasi', err,
                                      snackPosition: SnackPosition.BOTTOM);
                                } else {
                                  Get.back();
                                }
                              },
                        icon: e.locating.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Gunakan lokasi saya (GPS)'),
                      ),
                    ),
                    if (coords != null && r != null && km != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '$coords\nWilayah terdekat: ${r.name} (padanan ${r.analog}, ±${km.round()} km)',
                          style: textTheme.bodySmall,
                        ),
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final current = e.region.value;
                return ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.public),
                      title: const Text('Semua wilayah'),
                      subtitle: const Text('#1 – #1025'),
                      selected: current == null,
                      trailing: current == null ? const Icon(Icons.check) : null,
                      onTap: () async {
                        Get.back();
                        await e.selectRegion(null);
                      },
                    ),
                    for (final r in Region.all)
                      ListTile(
                        leading: const Icon(Icons.map_outlined),
                        title: Text(r.name),
                        subtitle: Text('${r.analog} • #${r.startId} – #${r.endId}'),
                        selected: current?.name == r.name,
                        trailing:
                            current?.name == r.name ? const Icon(Icons.check) : null,
                        onTap: () async {
                          Get.back();
                          await e.selectRegion(r);
                        },
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
