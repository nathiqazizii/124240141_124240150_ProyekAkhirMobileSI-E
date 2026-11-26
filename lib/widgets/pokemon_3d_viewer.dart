import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ---------------------------------------------------------------------------
// Membuat model "berisi" dari artwork 2D tanpa aset 3D:
//  1. Siluet artwork (alpha) dihitung jarak tepinya (distance transform).
//  2. Dibuat [_kSlices] irisan; irisan ke-k hanya memuat piksel yang jaraknya
//     dari tepi >= ambang ke-k, jadi makin ke tengah makin kecil.
//  3. Irisan ditumpuk di sumbu Z dengan profil membulat (sqrt) di sisi depan
//     dan belakang -> bentuk menggelembung seperti figur/balon, bukan gepeng.
// Warna tiap piksel tetap dari artwork asli, dengan bayangan lembut ke tepi.
// ---------------------------------------------------------------------------

const int _kSlices = 14;
const int _kTexWidth = 192;

class _SliceJob {
  final Uint8List rgba;
  final int w;
  final int h;
  const _SliceJob(this.rgba, this.w, this.h);
}

/// Berjalan di isolate terpisah lewat [compute].
List<Uint8List> _buildSlices(_SliceJob job) {
  final w = job.w, h = job.h, n = w * h;
  final src = job.rgba;
  const big = 1 << 20;

  final dist = Int32List(n);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final border = x == 0 || y == 0 || x == w - 1 || y == h - 1;
      dist[i] = (!border && src[i * 4 + 3] >= 48) ? big : 0;
    }
  }
  // Chamfer 3-4: lintasan maju lalu mundur.
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      var d = dist[i];
      if (d == 0) continue;
      if (x > 0) d = math.min(d, dist[i - 1] + 3);
      if (y > 0) {
        d = math.min(d, dist[i - w] + 3);
        if (x > 0) d = math.min(d, dist[i - w - 1] + 4);
        if (x < w - 1) d = math.min(d, dist[i - w + 1] + 4);
      }
      dist[i] = d;
    }
  }
  var dmax = 3;
  for (var y = h - 1; y >= 0; y--) {
    for (var x = w - 1; x >= 0; x--) {
      final i = y * w + x;
      var d = dist[i];
      if (d == 0) continue;
      if (x < w - 1) d = math.min(d, dist[i + 1] + 3);
      if (y < h - 1) {
        d = math.min(d, dist[i + w] + 3);
        if (x > 0) d = math.min(d, dist[i + w - 1] + 4);
        if (x < w - 1) d = math.min(d, dist[i + w + 1] + 4);
      }
      dist[i] = d;
      if (d > dmax && d < big) dmax = d;
    }
  }

  final result = <Uint8List>[];
  for (var k = 0; k < _kSlices; k++) {
    final threshold = k == 0 ? 0 : 3 + ((dmax - 3) * k / _kSlices);
    final shade = 0.70 + 0.30 * (k / (_kSlices - 1));
    final out = Uint8List(n * 4);
    for (var i = 0; i < n; i++) {
      final a = src[i * 4 + 3];
      if (a == 0) continue;
      if (k > 0 && dist[i] < threshold) continue;
      out[i * 4] = (src[i * 4] * shade).round();
      out[i * 4 + 1] = (src[i * 4 + 1] * shade).round();
      out[i * 4 + 2] = (src[i * 4 + 2] * shade).round();
      out[i * 4 + 3] = a;
    }
    result.add(out);
  }
  return result;
}

class _SolidModel {
  final List<ui.Image> slices;
  final int w;
  final int h;
  const _SolidModel(this.slices, this.w, this.h);
}

final Map<String, _SolidModel> _modelCache = <String, _SolidModel>{};

Future<ui.Image> _resolveImage(String url) {
  final completer = Completer<ui.Image>();
  final stream = ResizeImage(NetworkImage(url), width: _kTexWidth)
      .resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete(info.image);
      stream.removeListener(listener);
    },
    onError: (Object e, StackTrace? s) {
      if (!completer.isCompleted) completer.completeError(e, s);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

Future<ui.Image> _decodePixels(Uint8List bytes, int w, int h) {
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(bytes, w, h, ui.PixelFormat.rgba8888, c.complete);
  return c.future;
}

Future<_SolidModel> _loadModel(String url) async {
  final cached = _modelCache.remove(url);
  if (cached != null) {
    _modelCache[url] = cached; // tandai baru dipakai
    return cached;
  }
  final img = await _resolveImage(url);
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) throw StateError('Piksel gambar tidak terbaca');
  final rgba = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final raw =
      await compute(_buildSlices, _SliceJob(rgba, img.width, img.height));
  final images = <ui.Image>[
    for (final bytes in raw) await _decodePixels(bytes, img.width, img.height),
  ];
  final model = _SolidModel(images, img.width, img.height);
  _modelCache[url] = model;
  while (_modelCache.length > 10) {
    _modelCache.remove(_modelCache.keys.first);
  }
  return model;
}

/// Penampil Pokémon 3D "berisi".
///
/// - Mode biasa ([swipeMode] false): seret untuk memutar & memiringkan,
///   ketuk dua kali untuk jeda putar otomatis (dipakai di halaman detail).
/// - Mode geser ([swipeMode] true): untuk dipasang di dalam PageView. Putaran
///   mengikuti posisi geser halaman ([pageOffset]); ketuk untuk jeda/lanjut.
class Pokemon3DViewer extends StatefulWidget {
  final String imageUrl;
  final Color color;
  final double height;
  final bool swipeMode;

  /// Posisi halaman saat ini dikurangi indeks halaman ini (PageView).
  final double pageOffset;

  /// Bila false, animasi dihentikan (mis. halaman tetangga di PageView).
  final bool active;

  const Pokemon3DViewer({
    super.key,
    required this.imageUrl,
    required this.color,
    this.height = 300,
    this.swipeMode = false,
    this.pageOffset = 0,
    this.active = true,
  });

  @override
  State<Pokemon3DViewer> createState() => _Pokemon3DViewerState();
}

class _Pokemon3DViewerState extends State<Pokemon3DViewer>
    with SingleTickerProviderStateMixin {
  static const double _perspective = 0.0013;
  static const double _autoSpeed = 0.7; // rad/detik

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  _SolidModel? _model;
  bool _failed = false;

  double _yaw = -0.4;
  double _pitch = 0;
  double _yawVelocity = _autoSpeed;
  double _time = 0;
  bool _dragging = false;
  bool _autoRotate = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.active) _ticker.start();
    _load();
  }

  @override
  void didUpdateWidget(covariant Pokemon3DViewer old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) {
      _model = null;
      _failed = false;
      _load();
    }
    if (widget.active && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!widget.active && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = widget.imageUrl;
    try {
      final m = await _loadModel(url);
      if (!mounted || url != widget.imageUrl) return;
      setState(() => _model = m);
    } catch (_) {
      if (!mounted || url != widget.imageUrl) return;
      setState(() => _failed = true);
    }
  }

  void _onTick(Duration elapsed) {
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    _time += dt;
    if (!_dragging) {
      final target = _autoRotate ? _autoSpeed : 0.0;
      _yawVelocity += (target - _yawVelocity) * math.min(1.0, dt * 1.6);
      _yaw += _yawVelocity * dt;
      _pitch += (0 - _pitch) * math.min(1.0, dt * 4);
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _yaw += d.delta.dx * 0.012;
    _pitch = (_pitch - d.delta.dy * 0.008).clamp(-0.6, 0.6);
    _yawVelocity = (d.delta.dx * 0.012 * 60).clamp(-8.0, 8.0);
  }

  Matrix4 _matrix(double yaw, double bob, double z) => Matrix4.identity()
    ..setEntry(3, 2, _perspective)
    ..translateByDouble(0.0, bob, 0.0, 1.0)
    ..rotateX(_pitch)
    ..rotateY(yaw)
    ..translateByDouble(0.0, 0.0, z, 1.0);

  Widget _flatFallback(double yaw, double bob, double size) {
    return Transform(
      alignment: Alignment.center,
      transform: _matrix(yaw, bob, 0),
      child: _failed
          ? Icon(Icons.catching_pokemon,
              size: 120, color: Colors.white.withValues(alpha: 0.7))
          : Image.network(
              widget.imageUrl,
              height: size,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon,
                  size: 120, color: Colors.white.withValues(alpha: 0.7)),
            ),
    );
  }

  Widget _solidStage(_SolidModel m, double yaw, double bob, double size) {
    final scale = size / math.max(m.w, m.h);
    final pw = m.w * scale, ph = m.h * scale;
    final half = size * 0.17; // setengah tebal tubuh

    // (z, irisan, sisi belakang?)
    final entries = <(double, int, bool)>[];
    for (var k = 0; k < _kSlices; k++) {
      final u = k / _kSlices;
      final z = half * math.sqrt(1 - (1 - u) * (1 - u));
      entries.add((z, k, false));
      if (k > 0) entries.add((-z, k, true));
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    final ordered = math.cos(yaw) >= 0 ? entries : entries.reversed.toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        for (final e in ordered)
          Transform(
            alignment: Alignment.center,
            transform: _matrix(yaw, bob, e.$1),
            child: RawImage(
              image: m.slices[e.$2],
              width: pw,
              height: ph,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
              color: e.$3 ? Colors.black.withValues(alpha: 0.28) : null,
              colorBlendMode: e.$3 ? BlendMode.srcATop : null,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final off = widget.pageOffset;
    final yaw = _yaw + (widget.swipeMode ? off * 1.6 : 0);
    final bob = math.sin(_time * 1.8) * 6;
    final size = widget.height * 0.78;
    final m = _model;

    final stage = m == null
        ? _flatFallback(yaw, bob, size)
        : _solidStage(m, yaw, bob, size);

    final content = Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: widget.height * 0.06,
          child: CustomPaint(
            size: Size(widget.height * 0.95, widget.height * 0.26),
            painter: _PlatformPainter(
              color: widget.color,
              yaw: yaw,
              lift: bob,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: widget.height * 0.06),
          child: stage,
        ),
        if (!widget.swipeMode)
          Positioned(
            bottom: 0,
            child: Text(
              _autoRotate
                  ? 'Seret untuk memutar 3D  •  ketuk 2x untuk jeda'
                  : 'Seret untuk memutar 3D  •  ketuk 2x untuk lanjut',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          ),
      ],
    );

    final faded = widget.swipeMode
        ? Opacity(
            opacity: (1 - off.abs() * 0.7).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: (1 - off.abs() * 0.15).clamp(0.5, 1.0),
              child: content,
            ),
          )
        : content;

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.swipeMode
            ? () => setState(() => _autoRotate = !_autoRotate)
            : null,
        onDoubleTap: widget.swipeMode
            ? null
            : () => setState(() => _autoRotate = !_autoRotate),
        onPanStart: widget.swipeMode ? null : (_) => _dragging = true,
        onPanUpdate: widget.swipeMode ? null : _onPanUpdate,
        onPanEnd: widget.swipeMode ? null : (_) => _dragging = false,
        onPanCancel: widget.swipeMode ? null : () => _dragging = false,
        child: faded,
      ),
    );
  }
}

class _PlatformPainter extends CustomPainter {
  final Color color;
  final double yaw;
  final double lift;

  const _PlatformPainter({
    required this.color,
    required this.yaw,
    required this.lift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    final shrink = (1 - (lift + 6) / 60).clamp(0.6, 1.0);
    final shadow = Rect.fromCenter(
      center: rect.center,
      width: size.width * 0.5 * shrink,
      height: size.height * 0.3 * shrink,
    );
    canvas.drawOval(
      shadow,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25 * shrink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.9);
    final ringRect = rect.deflate(size.width * 0.08);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        ringRect,
        yaw * 1.5 + i * math.pi / 2,
        math.pi / 4,
        false,
        ring,
      );
    }
    canvas.drawOval(
      ringRect.deflate(size.width * 0.06),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_PlatformPainter old) =>
      old.yaw != yaw || old.lift != lift || old.color != color;
}
