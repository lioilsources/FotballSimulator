import 'dart:ui';

import '../core/tuning.dart';
import '../core/vec3.dart';

class KickIntent {
  final Vec2 contactOffset;
  final double swingCurve;
  final double power;
  const KickIntent(this.contactOffset, this.swingCurve, this.power);
}

/// Swipe gesto → KickIntent (port `swipe_input.gd`, VOLLEY_PLAN.md §4).
/// Touch-down na overlay míči = kontaktní bod, dráha prstu = zakřivení,
/// rychlost = síla, puštění = timing (timing_error počítá Game).
class SwipeTracker {
  bool tracking = false;
  final List<Offset> points = [];
  Vec2 contactOffset = Vec2.zero;
  Duration _tStart = Duration.zero;

  static double overlayRadius(Size size) =>
      size.width * T.overlayBallScreenFrac * 0.5;

  static Offset overlayCenter(Size size, double bottomInset) => Offset(
      size.width * 0.5, size.height - overlayRadius(size) - 40.0 - bottomInset);

  /// true = gesto začalo (dotyk na overlay míči).
  bool start(Offset pos, Duration t, Size size, double bottomInset) {
    final center = overlayCenter(size, bottomInset);
    final radius = overlayRadius(size);
    final off = pos - center;
    if (off.distance > radius) return false; // gesto začíná jen na overlay míči
    tracking = true;
    points
      ..clear()
      ..add(pos);
    _tStart = t;
    // obrazovkové y roste dolů → na míči je +y nahoře
    contactOffset = Vec2(off.dx / radius, -off.dy / radius).limitLength(1.0);
    return true;
  }

  void move(Offset pos) {
    if (tracking) addPoint(points, pos);
  }

  /// Přidá vzorek dráhy prstu. Mikro-posuny pod swipeSampleMinPx se
  /// zahazují; při přetečení swipeMaxPoints se dráha zředí na polovinu
  /// (první a poslední bod zůstávají).
  static void addPoint(List<Offset> pts, Offset pos) {
    if (pts.isNotEmpty && (pts.last - pos).distance < T.swipeSampleMinPx) return;
    pts.add(pos);
    if (pts.length <= T.swipeMaxPoints) return;
    final last = pts.last;
    final thinned = [for (var i = 0; i < pts.length; i += 2) pts[i]];
    if (thinned.last != last) thinned.add(last);
    pts
      ..clear()
      ..addAll(thinned);
  }

  void cancel() => tracking = false;

  /// Vrátí intent, nebo null když gesto bylo moc krátké (= zrušené).
  KickIntent? finish(Offset pos, Duration t) {
    tracking = false;
    points.add(pos);
    final duration = (t - _tStart).inMicroseconds / 1e6;

    var pathLen = 0.0;
    for (var i = 1; i < points.length; i++) {
      pathLen += (points[i] - points[i - 1]).distance;
    }
    final chord = points.last - points.first;

    if (pathLen < T.swipeMinLengthPx ||
        chord.distance < T.swipeDeadzonePx ||
        duration < T.swipeMinDuration) {
      return null;
    }

    // síla: rychlost prstu normalizovaná na DPI (logical px/s → in/s)
    final power =
        ((pathLen / duration) / T.logicalDpi / T.swipePowerFullIns).clamp(0.0, 1.0);

    // zakřivení: max podepsaná kolmá odchylka od tětivy / půlka tětivy;
    // kladné = oblouk doprava vůči směru tahu
    final dir = chord / chord.distance;
    var maxDev = 0.0;
    for (final p in points) {
      final rel = p - points.first;
      final dev = dir.dx * rel.dy - dir.dy * rel.dx;
      if (dev.abs() > maxDev.abs()) maxDev = dev;
    }
    final curve = (maxDev / (chord.distance * 0.5)).clamp(-1.0, 1.0);

    return KickIntent(contactOffset, curve, power);
  }
}
