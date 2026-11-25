import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Penampil Pokémon pseudo-3D tanpa dependensi tambahan.
///
/// Artwork 2D di-"ekstrusi" menjadi beberapa lapisan yang ditumpuk pada sumbu Z,
/// lalu diputar dengan perspektif `Matrix4`. Efeknya seperti figur bertebal:
/// - seret jari untuk memutar (yaw) dan memiringkan (pitch),
/// - berputar sendiri saat dilepas (dengan inersia),
/// - ketuk dua kali untuk jeda/lanjut putar otomatis,
/// - melayang naik-turun di atas platform bercahaya.
class Pokemon3DViewer extends StatefulWidget {
  final String imageUrl;
  final Color color;
  final double height;

  const Pokemon3DViewer({
    super.key,
    required this.imageUrl,
    required this.color,
    this.height = 300,
  });

  @override
  State<Pokemon3DViewer> createState() => _Pokemon3DViewerState();
}

class _Pokemon3DViewerState extends State<Pokemon3DViewer>
    with SingleTickerProviderStateMixin {
  static const int _layers = 12;
  static const double _thickness = 28; // total tebal ekstrusi (px)
  static const double _perspective = 0.0013;
  static const double _autoSpeed = 0.7; // rad/detik

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  double _yaw = -0.4;
  double _pitch = 0;
  double _yawVelocity = _autoSpeed;
  double _time = 0;
  bool _dragging = false;
  bool _autoRotate = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final facingFront = math.cos(_yaw) >= 0;
    final bob = math.sin(_time * 1.8) * 6;
    final sideColor = Color.lerp(widget.color, Colors.black, 0.55)!;
    final backColor = Color.lerp(widget.color, Colors.black, 0.25)!;

    // Urutan gambar: lapisan terjauh dari penonton lebih dulu.
    final order = List<int>.generate(_layers, (i) => i);
    final sorted = facingFront ? order : order.reversed.toList();
    final visible = facingFront ? _layers - 1 : 0;

    final stage = Stack(
      alignment: Alignment.center,
      children: [
        for (final i in sorted)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, _perspective)
              ..translate(0.0, bob, 0.0)
              ..rotateX(_pitch)
              ..rotateY(_yaw)
              ..translate(
                0.0,
                0.0,
                (i / (_layers - 1) - 0.5) * _thickness,
              ),
            child: Image.network(
              widget.imageUrl,
              height: widget.height * 0.78,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              // Lapisan yang menghadap penonton berwarna asli; sisanya gelap
              // sehingga tepi terlihat seperti sisi tebal figur.
              color: i == visible
                  ? (facingFront ? null : backColor.withValues(alpha: 0.35))
                  : sideColor,
              colorBlendMode: i == visible
                  ? (facingFront ? null : BlendMode.srcATop)
                  : BlendMode.srcATop,
              errorBuilder: (_, __, ___) => Icon(
                Icons.catching_pokemon,
                size: 120,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _dragging = true,
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => _dragging = false,
        onPanCancel: () => _dragging = false,
        onDoubleTap: () => setState(() => _autoRotate = !_autoRotate),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Platform + bayangan.
            Positioned(
              bottom: widget.height * 0.06,
              child: CustomPaint(
                size: Size(widget.height * 0.95, widget.height * 0.26),
                painter: _PlatformPainter(
                  color: widget.color,
                  yaw: _yaw,
                  lift: bob,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: widget.height * 0.06),
              child: stage,
            ),
            Positioned(
              bottom: 0,
              child: Text(
                _autoRotate
                    ? 'Seret untuk memutar 3D  •  ketuk 2x untuk jeda'
                    : 'Seret untuk memutar 3D  •  ketuk 2x untuk lanjut',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
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

    // Cahaya dasar.
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

    // Bayangan Pokémon: mengecil saat melayang naik.
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

    // Cincin putar yang mengikuti yaw.
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
