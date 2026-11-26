import 'dart:math' as math;

/// Wilayah (region) dalam game Pokémon beserta padanan dunia nyatanya.
/// Dipakai di alur "Jelajah Wilayah": lokasi GPS pengguna -> wilayah terdekat
/// -> daftar Pokémon wilayah itu -> notifikasi sambutan.
class Region {
  final String name;
  final String analog;
  final double lat;
  final double lng;
  final int startId;
  final int endId;

  const Region({
    required this.name,
    required this.analog,
    required this.lat,
    required this.lng,
    required this.startId,
    required this.endId,
  });

  int get count => endId - startId + 1;
  bool contains(int id) => id >= startId && id <= endId;

  static const List<Region> all = [
    Region(name: 'Kanto', analog: 'Kanto, Jepang', lat: 35.68, lng: 139.69, startId: 1, endId: 151),
    Region(name: 'Johto', analog: 'Kansai, Jepang', lat: 34.69, lng: 135.50, startId: 152, endId: 251),
    Region(name: 'Hoenn', analog: 'Kyushu, Jepang', lat: 33.59, lng: 130.40, startId: 252, endId: 386),
    Region(name: 'Sinnoh', analog: 'Hokkaido, Jepang', lat: 43.06, lng: 141.35, startId: 387, endId: 493),
    Region(name: 'Unova', analog: 'New York, AS', lat: 40.71, lng: -74.01, startId: 494, endId: 649),
    Region(name: 'Kalos', analog: 'Prancis', lat: 48.86, lng: 2.35, startId: 650, endId: 721),
    Region(name: 'Alola', analog: 'Hawaii, AS', lat: 21.31, lng: -157.86, startId: 722, endId: 809),
    Region(name: 'Galar', analog: 'Britania Raya', lat: 51.51, lng: -0.13, startId: 810, endId: 905),
    Region(name: 'Paldea', analog: 'Semenanjung Iberia', lat: 40.42, lng: -3.70, startId: 906, endId: 1025),
  ];

  /// Jarak dua koordinat (rumus haversine) dalam km.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// Wilayah terdekat dari koordinat pengguna beserta jaraknya (km).
  static (Region, double) nearest(double lat, double lng) {
    Region best = all.first;
    var bestDist = double.infinity;
    for (final r in all) {
      final d = distanceKm(lat, lng, r.lat, r.lng);
      if (d < bestDist) {
        bestDist = d;
        best = r;
      }
    }
    return (best, bestDist);
  }

  static Region? byName(String? name) {
    for (final r in all) {
      if (r.name == name) return r;
    }
    return null;
  }
}
