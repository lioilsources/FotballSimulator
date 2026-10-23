import 'dart:math' as math;
import 'dart:ui';

import '../core/tuning.dart';
import '../core/vec3.dart';

/// Perspektivní kamera podle Camera3D z main.tscn (pozice, pitch kolem x,
/// vertikální FOV) + minimální horizontální FOV a lens shift pro portrait.
/// Kouká směrem -z.
class Camera {
  final Size size;
  final Vec3 pos;
  final double _cos, _sin, _focal, _cy;
  static const near = 0.1;

  Camera(this.size, {this.pos = T.cameraPos, double pitch = T.cameraPitch})
      : _cos = math.cos(pitch),
        _sin = math.sin(pitch),
        _focal = math.min(
          size.height * 0.5 / math.tan(T.cameraFovDeg * math.pi / 360),
          size.width * 0.5 / math.tan(T.cameraMinHFovDeg * math.pi / 360),
        ),
        _cy = size.height *
            (size.height > size.width ? T.cameraCenterYFrac : 0.5);

  /// Svět → prostor kamery (inverzní rotace kolem x).
  Vec3 toView(Vec3 p) {
    final d = p - pos;
    return Vec3(d.x, d.y * _cos + d.z * _sin, -d.y * _sin + d.z * _cos);
  }

  /// Hloubka před kamerou (kladná = viditelné).
  double depth(Vec3 p) => -toView(p).z;

  bool isBehind(Vec3 p) => depth(p) < near;

  Offset project(Vec3 p) {
    final v = toView(p);
    final d = math.max(-v.z, near);
    return Offset(
      size.width * 0.5 + _focal * v.x / d,
      _cy - _focal * v.y / d,
    );
  }

  /// Velikost světové délky [worldLen] v pixelech v hloubce bodu [p].
  double scaleAt(Vec3 p, double worldLen) =>
      _focal * worldLen / math.max(depth(p), near);

  /// Obrazovková y horizontu (bod v nekonečnu ve směru -z na úrovni očí).
  double get horizonY => _cy + _focal * (_sin / _cos);
}
