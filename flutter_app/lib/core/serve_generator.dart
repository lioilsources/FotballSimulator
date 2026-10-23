import 'dart:math' as math;

import 'tuning.dart';
import 'vec3.dart';

class Serve {
  final Vec3 pos, vel, omega;
  const Serve(this.pos, this.vel, this.omega);
}

/// PCG32 — vlastní implementace, aby seed dával stejnou sekvenci napříč
/// verzemi Dart SDK (dart:math Random to negarantuje). Sekvence se NEshoduje
/// s Godot RandomNumberGenerator — replaye nejsou přenositelné mezi verzemi.
class Pcg32 {
  static const _mult = 6364136223846793005;
  static const _inc = 1442695040888963407;
  int _state = 0;

  Pcg32(int seed) {
    _next();
    _state += seed;
    _next();
  }

  int _next() {
    final old = _state;
    _state = old * _mult + _inc; // 64bit wrap
    final xorShifted = (((old >>> 18) ^ old) >>> 27) & 0xFFFFFFFF;
    final rot = old >>> 59;
    return ((xorShifted >>> rot) | (xorShifted << ((-rot) & 31))) & 0xFFFFFFFF;
  }

  double nextDouble() => _next() / 4294967296.0;

  double range(double lo, double hi) => lo + (hi - lo) * nextDouble();
}

/// Seedovatelné nadhozy (port `serve_generator.gd`, VOLLEY_PLAN.md §5.1):
/// stejný seed ⇒ stejná sekvence míčů.
class ServeGenerator {
  final Pcg32 _rng;

  ServeGenerator([int seed = -1])
      : _rng = Pcg32(seed >= 0 ? seed : math.Random().nextInt(1 << 32));

  /// Míč přilétá obloukem zepředu/ze strany, dopadá ~1.5–2.5 m před hráče
  /// (origin) a přiskáče do kop-zóny. Balistika bez dragu.
  Serve nextServe() {
    final start = Vec3(
      _rng.range(-2.5, 2.5),
      _rng.range(0.6, 1.4),
      -_rng.range(6.0, 9.0),
    );
    final landing = Vec3(
      _rng.range(-0.5, 0.5),
      T.ballRadius,
      -_rng.range(1.5, 2.5),
    );
    final flightTime = _rng.range(0.9, 1.4);

    final d = landing - start;
    final vel = Vec3(
      d.x / flightTime,
      d.y / flightTime + 0.5 * (-T.gravity.y) * flightTime,
      d.z / flightTime,
    );
    // lehký náhodný spin, ať odskoky nejsou sterilní
    final spin = Vec3(
      _rng.range(-8.0, 8.0),
      _rng.range(-5.0, 5.0),
      _rng.range(-3.0, 3.0),
    );
    return Serve(start, vel, spin);
  }
}
