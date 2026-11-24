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
///
/// 64bitový stav je ve dvou 32bitových polovinách a násobí se po 16bitových
/// kouscích, takže výsledek je stejný v Dart VM i v JavaScriptu (web), kde
/// celé číslo nad 2^53 nejde přesně uložit.
class Pcg32 {
  static const _two32 = 4294967296;
  static const _multHi = 0x5851F42D, _multLo = 0x4C957F2D; // 6364136223846793005
  static const _incHi = 0x14057B7E, _incLo = 0xF767814F; // 1442695040888963407
  int _hi = 0, _lo = 0;

  Pcg32(int seed) {
    _next();
    _add(seed ~/ _two32 % _two32, seed % _two32);
    _next();
  }

  /// Dolních 32 bitů a × b (obojí < 2^32), přesně i v double.
  static int _mulLo(int a, int b) {
    final a0 = a & 0xFFFF, a1 = (a ~/ 65536) & 0xFFFF;
    final b0 = b & 0xFFFF, b1 = (b ~/ 65536) & 0xFFFF;
    return (a0 * b0 + ((a1 * b0 + a0 * b1) % 65536) * 65536) % _two32;
  }

  /// Horních 32 bitů a × b (obojí < 2^32).
  static int _mulHi(int a, int b) {
    final a0 = a & 0xFFFF, a1 = (a ~/ 65536) & 0xFFFF;
    final b0 = b & 0xFFFF, b1 = (b ~/ 65536) & 0xFFFF;
    final p00 = a0 * b0, p01 = a0 * b1, p10 = a1 * b0;
    final mid = p00 ~/ 65536 + (p01 & 0xFFFF) + (p10 & 0xFFFF);
    return (a1 * b1 + p01 ~/ 65536 + p10 ~/ 65536 + mid ~/ 65536) % _two32;
  }

  void _add(int hi, int lo) {
    final l = _lo + lo;
    _lo = l % _two32;
    _hi = (_hi + hi + l ~/ _two32) % _two32;
  }

  int _next() {
    final oh = _hi, ol = _lo;
    // state = old * mult + inc (mod 2^64)
    _hi = (_mulHi(ol, _multLo) + _mulLo(ol, _multHi) + _mulLo(oh, _multLo)) % _two32;
    _lo = _mulLo(ol, _multLo);
    _add(_incHi, _incLo);
    // xorShifted = ((old >>> 18) ^ old) >>> 27, low 32 bits
    final xh = oh ^ (oh >>> 18);
    final xl = ol ^ (((ol >>> 18) | ((oh & 0x3FFFF) * 16384)) % _two32);
    final xorShifted = ((xl >>> 27) | ((xh & 0x7FFFFFF) * 32)) % _two32;
    final rot = oh >>> 27;
    if (rot == 0) return xorShifted;
    return ((xorShifted >>> rot) | ((xorShifted * (1 << (32 - rot))) % _two32)) % _two32;
  }

  double nextDouble() => _next() / 4294967296.0;

  double range(double lo, double hi) => lo + (hi - lo) * nextDouble();
}

/// Seedovatelné nadhozy (port `serve_generator.gd`, VOLLEY_PLAN.md §5.1):
/// stejný seed ⇒ stejná sekvence míčů.
class ServeGenerator {
  final Pcg32 _rng;

  ServeGenerator([int seed = -1]) : _rng = Pcg32(seed >= 0 ? seed : math.Random().nextInt(4294967296));

  /// Míč přilétá obloukem zepředu/ze strany, dopadá ~1.5–2.5 m před hráče
  /// (origin) a přiskáče do kop-zóny. Balistika bez dragu.
  Serve nextServe() {
    final start = Vec3(_rng.range(-2.5, 2.5), _rng.range(0.6, 1.4), -_rng.range(6.0, 9.0));
    final landing = Vec3(_rng.range(-0.5, 0.5), T.ballRadius, -_rng.range(1.5, 2.5));
    final flightTime = _rng.range(0.9, 1.4);

    final d = landing - start;
    final vel = Vec3(d.x / flightTime, d.y / flightTime + 0.5 * (-T.gravity.y) * flightTime, d.z / flightTime);
    // lehký náhodný spin, ať odskoky nejsou sterilní
    final spin = Vec3(_rng.range(-8.0, 8.0), _rng.range(-5.0, 5.0), _rng.range(-3.0, 3.0));
    return Serve(start, vel, spin);
  }
}
