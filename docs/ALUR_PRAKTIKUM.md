# Alur Aplikasi per Materi Praktikum

Setiap materi praktikum punya **alur (flow) sendiri** di aplikasi, dan fitur dari
materi itu **berperan di dalam alur**, bukan sekadar ada. Semua alur saling tersambung
dalam satu perjalanan pengguna:

```
Splash ─► (belum login & pertama kali) Onboarding ─► Login/Register ─► Home
Home: [Dashboard 3D] [Jelajah] [Favorit] [Profil]

Dashboard ─ geser Pokémon ─► detail ikut berubah ─► Detail lengkap ─► Bandingkan
    │                              │                     │
    │ chip wilayah ─► GPS ─► wilayah terdekat ─► daftar difilter ─► notifikasi ─► Detail
    └ "Terakhir dilihat" (local storage) ◄───────── dicatat saat Detail dibuka
```

| Pertemuan | Materi | Alur di aplikasi | Peran fitur dalam alur |
|---|---|---|---|
| Pra | Setup Flutter | Build & konfigurasi | `tool/patch_android.py`, `lib/secrets.dart`, `docs/BUILD_APK.md` |
| 1 | OOP & Dart | **Analisis Pokémon** | Model OOP menghitung tier & kelemahan yang tampil di Dashboard/Detail |
| 2 | Widget | **Onboarding & komposisi UI** | Widget kustom dipakai ulang di semua alur |
| 3 | State & Data | **Bandingkan Pokémon** | `setState` + data antar halaman menentukan hasil adu |
| 4 | Navigation | **Gerbang & perpindahan halaman** | Route guard, argumen, tumpukan halaman, buka dari notifikasi |
| 6 | HTTP (API) | **Detail berantai** | Request berantai species → evolusi, paging, filter wilayah |
| 7 | Local Storage | **Ingat & offline** | Cache, riwayat, terakhir dilihat, tema, wilayah terakhir |
| 8 | Notification & Location | **Jelajah Wilayah** | GPS → wilayah → daftar → notifikasi → detail |
| 9 | GetX | **State bersama** | Satu controller menggerakkan Dashboard, Jelajah, dan Profil sekaligus |

> Pertemuan 5 tidak ada pada rincian jadwal, jadi tidak dipetakan.

---

## Pertemuan 1: OOP & Dart, alur "Analisis Pokémon"

**Alur:** buka Pokémon di Dashboard/Detail → aplikasi menghitung **tier kekuatan** dan
**kelemahan/ketahanan tipe** → ditampilkan sebagai kartu Tier dan chip `×2`, `×½`, `×0`.

| Konsep OOP/Dart | Dipakai di | Peran dalam alur |
|---|---|---|
| Kelas abstrak `PokemonBase` + pewarisan | `lib/models/pokemon.dart` | Induk `PokemonSummary` & `Pokemon` (id, nama, gambar) |
| Interface `Comparable` | `PokemonBase.compareTo` | Urutan alami berdasarkan nomor Pokédex |
| `mixin PowerAnalysis` | `Pokemon with PowerAnalysis` | Menghitung `totalPower` dan `tier` dari `stats` |
| `enum PowerTier` (field + const constructor) | `pokemon.dart` | S/A/B/C/D beserta label |
| `enum PokemonType` + method `attackMultiplier` | `lib/models/pokemon_type.dart` | Tabel efektivitas 18 tipe |
| Record & koleksi (`Map`, `Set`) | `_rawChart` | Data tabel tipe |
| Kelas `TypeMatchup` + factory constructor | `pokemon_type.dart` | Menggabungkan 2 tipe → kelemahan |
| Extension method `.pretty`, `.pokedexNo` | `lib/utils/pokemon_utils.dart` | Pemformatan teks di UI |
| Null safety, `async/await` | seluruh proyek | Data opsional & request jaringan |

**Demo:** buka Pokémon bertipe ganda (mis. Charizard) → lihat Tier dan "Lemah terhadap Rock ×4".

## Pertemuan 2: Widget, alur "Onboarding & komposisi UI"

**Alur:** instal pertama kali → Splash → **Onboarding 3 slide** → Login. Setelah itu tidak muncul lagi.

- `OnboardingPage`: `PageView`, `AnimatedContainer` (indikator titik), `AnimatedSwitcher` (tombol Lanjut/Mulai).
- Widget yang dipakai ulang lintas alur: `PokemonCard` (+ `Tilt3D`), `TypeChip/TypeBadge`,
  `StatRow`, `InfoCard`, `PowerSummary`, `MatchupSection`, `SpeciesSection`, `RegionSheet`,
  `Pokemon3DViewer` (`CustomPaint` untuk platform bercahaya).
- Layout: `Stack`, `Column/Row`, `ListView`, `GridView`, `TweenAnimationBuilder`.

**Demo:** hapus data aplikasi → buka → onboarding muncul; kartu di Jelajah miring saat disentuh.

## Pertemuan 3: State & Data, alur "Bandingkan Pokémon"

**Alur:** Detail Pokémon A → tombol **Bandingkan** → pilih Pokémon B (bottom sheet pencarian) →
statistik berdampingan → **hasil** (siapa unggul kekuatan & tipe).

- `ComparePage` sengaja memakai `StatefulWidget` + `setState` (state lokal): `_b`, `_loadingB`, `_error`.
- Data A dikirim lewat argumen navigasi; B diambil dari API lalu disimpan di state.
- Form & state lain: login/register (`Form`, validasi, `_obscure`), `_index` tab, `_PickerSheet` (filter pencarian).

**Demo:** Detail Charizard → Bandingkan → pilih Blastoise → lihat selisih dan keunggulan tipe.

## Pertemuan 4: Navigation, alur "Gerbang & perpindahan halaman"

**Alur:** Splash memutuskan tujuan → halaman terproteksi → navigasi bertingkat → kembali.

- Named routes + `AuthMiddleware` (tanpa sesi → Login) di `lib/routes/app_routes.dart`.
- `Get.toNamed(..., arguments: ...)` mengirim Pokémon antar halaman (Dashboard → Detail → Bandingkan).
- Halaman Detail **ditumpuk**: dari evolusi atau "Terakhir dilihat" (`preventDuplicates: false`), tombol Back mundur satu per satu.
- `Get.offAllNamed` setelah login/logout; `Get.bottomSheet`/`Get.dialog` untuk pilihan.
- **Buka dari notifikasi:** ketuk notifikasi → langsung ke Detail (`NotificationService.openPayload`).
- Bottom navigation + `IndexedStack`: Dashboard, Jelajah, Favorit, Profil.

**Demo:** Detail Charmander → ketuk Charizard di rantai evolusi → Back → kembali ke Charmander.

## Pertemuan 6: HTTP Request (API), alur "Detail berantai"

**Alur:** buka Detail → request 1 `/pokemon/{id}` → (terpisah) request 2 `/pokemon-species/{id}` →
request 3 `/evolution-chain/{id}` → tampil deskripsi + rantai evolusi.

- `PokemonApiService`: `fetchPage` (paging + filter wilayah lewat `offset`), `fetchByType`, `fetchAllNames`, `fetchDetail`, `fetchSpecies`.
- `SpeciesSection` punya loading/error/**Coba lagi** sendiri, jadi gagalnya deskripsi tidak merusak detail.
- Penanganan error: timeout, tidak ada koneksi, 404, format tidak valid (`ApiException`).
- Pencarian & filter tipe memakai data API; Dashboard memakai halaman API sesuai wilayah.

**Demo:** matikan internet → muncul pesan & tombol Coba lagi di bagian deskripsi.

## Pertemuan 7: Local Storage, alur "Ingat & offline"

**Alur:** data yang pernah dibuka **disimpan** → dipakai lagi tanpa internet → mengubah pengalaman berikutnya.

| Data | Key / metode | Peran dalam alur |
|---|---|---|
| Cache detail, nama, tipe, species | `pokemon_*`, `species_*`, … | Buka ulang tanpa internet |
| Riwayat pencarian | `search_history` | Saran pencarian |
| **Terakhir dilihat** | `recent_viewed` | Strip di Dashboard, dicatat saat Detail dibuka |
| Status onboarding | `onboarding_done` | Splash memutuskan Onboarding atau Login |
| Tema | `theme_mode` | Terang/gelap bertahan setelah aplikasi ditutup |
| Wilayah terakhir | `last_region` | Dashboard & Jelajah langsung terfilter saat dibuka |
| Pengingat & notifikasi harian | `reminder_enabled`, `daily_pokemon`, `last_daily_date` | Notifikasi hanya sekali per hari |

**Demo:** buka beberapa Pokémon → tutup aplikasi → buka lagi → "Terakhir dilihat" masih ada.

## Pertemuan 8: Notification & Location-Based Service, alur "Jelajah Wilayah"

**Alur:** Dashboard → chip **Wilayah** → **Gunakan lokasi saya** → izin & koordinat GPS →
**wilayah terdekat** (padanan dunia nyata: Kanto=Jepang, Kalos=Prancis, Galar=Inggris, dst.) →
daftar Pokémon difilter ke wilayah itu → **notifikasi sambutan** → ketuk → Detail Pokémon pertama.

- `LocationService` (cek GPS, izin, koordinat) → `Region.nearest` (haversine) → `ExploreController`.
- Notifikasi: pengingat harian, **Pokémon hari ini** (sekali per hari saat aplikasi dibuka), **sambutan wilayah**, dan tombol coba.
- Izin diminta pada saat dibutuhkan, dengan pesan jelas bila ditolak.
- Bisa memilih wilayah manual bila GPS mati atau ditolak.

**Demo:** Dashboard → Wilayah → GPS → daftar berubah ke wilayah terdekat → notifikasi muncul → ketuk.

## Pertemuan 9: GetX, alur "State bersama"

**Alur:** satu perubahan state menggerakkan beberapa layar sekaligus.

- `ExploreController` memegang wilayah aktif; saat berubah, `PokemonController` memuat ulang daftar →
  **Dashboard, Jelajah, dan Profil** berubah bersama lewat `Obx`.
- `ThemeController` mengubah tema seluruh aplikasi secara reaktif (`Get.changeThemeMode`) dan menyimpannya.
- `AuthController` + `ever()` → login memuat favorit, logout mengosongkannya.
- `FavoriteController` memakai pembaruan optimistis (UI berubah dulu, dibatalkan bila gagal).
- `debounce` pada pencarian, `Bindings` (`AppBinding`), `Get.snackbar/dialog/bottomSheet`, `Get.toNamed`.

**Demo:** pilih wilayah di Dashboard → pindah ke Jelajah (daftar sudah terfilter) → Profil menampilkan wilayah yang sama.
