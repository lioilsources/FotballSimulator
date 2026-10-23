// Port tests/swipe_test.gd (výběr) — geometrie gesta a strop vzorků.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/core/tuning.dart';
import 'package:fotball_simulator/ui/swipe_input.dart';

void main() {
  const size = Size(400, 800);
  final center = SwipeTracker.overlayCenter(size, 0);

  KickIntent? swipe(List<Offset> path, double seconds) {
    final s = SwipeTracker();
    expect(s.start(path.first, Duration.zero, size, 0), isTrue);
    for (final p in path.skip(1)) {
      s.move(p);
    }
    return s.finish(path.last,
        Duration(microseconds: (seconds * 1e6).round()));
  }

  test('rovný rychlý tah nahoru = plná síla, bez křivky', () {
    final path = [for (var i = 0; i <= 20; i++) center - Offset(0, i * 20.0)];
    final k = swipe(path, 0.1)!;
    expect(k.power, 1.0);
    expect(k.swingCurve.abs(), lessThan(0.01));
  });

  test('oblouk doprava = kladná křivka', () {
    final path = [
      for (var i = 0; i <= 20; i++)
        center + Offset(40 * (1 - ((i - 10) / 10) * ((i - 10) / 10)), -i * 15.0)
    ];
    expect(swipe(path, 0.2)!.swingCurve, greaterThan(0.2));
  });

  test('krátký tah / moc rychlé puštění = zrušené gesto', () {
    expect(swipe([center, center - const Offset(0, 20)], 0.1), isNull);
    final ok = [center, center - const Offset(0, 100)];
    expect(swipe(ok, T.swipeMinDuration * 0.5), isNull);
    expect(swipe(ok, 0.1), isNotNull);
  });

  test('pod overlay míčem gesto nezačne', () {
    expect(SwipeTracker().start(const Offset(5, 5), Duration.zero, size, 0), isFalse);
  });

  test('strop vzorků a mikro-posuny', () {
    final pts = <Offset>[const Offset(0, 0)];
    SwipeTracker.addPoint(pts, const Offset(0.5, 0));
    expect(pts.length, 1, reason: 'posun pod swipeSampleMinPx se ignoruje');
    for (var i = 1; i < 2000; i++) {
      SwipeTracker.addPoint(pts, Offset(i * 3.0, 0));
    }
    expect(pts.length, lessThanOrEqualTo(T.swipeMaxPoints));
    expect(pts.first, Offset.zero);
    expect(pts.last, const Offset(1999 * 3.0, 0));
  });
}
