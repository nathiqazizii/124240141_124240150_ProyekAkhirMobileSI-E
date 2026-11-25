import 'package:flutter/material.dart';

/// Memiringkan [builder] secara 3D mengikuti posisi sentuhan.
///
/// Memakai [Listener] (bukan GestureDetector) agar tidak bersaing dengan
/// gestur scroll pada daftar. Nilai `tilt` yang diberikan ke builder berada
/// di rentang -1..1 pada tiap sumbu, berguna untuk efek paralaks/kilau.
class Tilt3D extends StatefulWidget {
  final Widget Function(BuildContext context, Offset tilt) builder;
  final double maxAngle;

  const Tilt3D({super.key, required this.builder, this.maxAngle = 0.2});

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  Offset _target = Offset.zero;
  bool _pressed = false;

  void _update(Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    final nx = ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny = ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
    setState(() {
      _pressed = true;
      _target = Offset(nx, ny);
    });
  }

  void _release() {
    if (!_pressed) return;
    setState(() {
      _pressed = false;
      _target = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _update(e.localPosition),
      onPointerMove: (e) => _update(e.localPosition),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(end: _target),
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 450),
        curve: _pressed ? Curves.easeOut : Curves.elasticOut,
        builder: (context, tilt, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-tilt.dy * widget.maxAngle)
              ..rotateY(tilt.dx * widget.maxAngle)
              ..scale(_pressed ? 1.03 : 1.0),
            child: widget.builder(context, tilt),
          );
        },
      ),
    );
  }
}
