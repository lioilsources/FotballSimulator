// Port tests/physics_test.gd. Referenční hodnoty z nezávislé Python
// implementace stejného modelu (float64, semi-implicit Euler 120 Hz).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/core/ball_physics.dart';
import 'package:fotball_simulator/core/serve_generator.dart';
import 'package:fotball_simulator/core/tuning.dart';
import 'package:fotball_simulator/core/vec3.dart';

const refRangeNoSpin = 38.921;
const refApexNoSpin = 8.256;
const refXSidespin = -9.693;
const refRangeTopspin = 32.982;
const maxTicks = 120 * 12;

/// Debug kop z plánu: 25 m/s @ 35° směrem -z.
Vec3 kickVel() {
  const a = 35 * math.pi / 180;
  return Vec3(0, 25 * math.sin(a), -25 * math.cos(a));
}

({double range, double x, double apex}) fly(Vec3 vel, Vec3 spin) {
  final ball = BallPhysics()
    ..position = const Vec3(0, T.ballRadius, 0)
    ..launch(vel, spin);
  var apex = 0.0;
  for (var i = 0; ball.bounceCount < 1 && i < maxTicks; i++) {
    ball.step(T.physicsDt);
    apex = math.max(apex, ball.position.y);
  }
  return (range: -ball.position.z, x: ball.position.x, apex: apex);
}

Matcher near(double ref, [double rel = 0.05]) => closeTo(ref, ref.abs() * rel);

void main() {
  test('dolet a vrchol bez spinu', () {
    final r = fly(kickVel(), Vec3.zero);
    expect(r.range, near(refRangeNoSpin));
    expect(r.apex, near(refApexNoSpin));
    expect(r.x.abs(), lessThan(0.05));
  });

  test('faleš: boční výchylka', () {
    expect(fly(kickVel(), const Vec3(0, 50, 0)).x, near(refXSidespin));
  });

  test('topspin nedoletí', () {
    final r = fly(kickVel(), const Vec3(-40, 0, 0));
    expect(r.range, near(refRangeTopspin));
    expect(r.range, lessThan(refRangeNoSpin * 0.9));
  });

  test('restituce odskoku', () {
    var impact = 0.0;
    var vyAfter = 0.0;
    final ball = BallPhysics()
      ..position = const Vec3(0, 2, 0)
      ..launch(Vec3.zero, Vec3.zero);
    ball.onBounced = (_, s) {
      impact = s;
      vyAfter = ball.vel.y;
    };
    for (var i = 0; ball.bounceCount < 1 && i < maxTicks; i++) {
      ball.step(T.physicsDt);
    }
    expect(vyAfter / impact, closeTo(T.restitution, 0.001));
  });

  test('serve: stejný seed ⇒ stejná sekvence i trajektorie', () {
    final a = ServeGenerator(42), b = ServeGenerator(42);
    final first = a.nextServe();
    final firstB = b.nextServe();
    expect(first.pos, firstB.pos);
    for (var i = 0; i < 4; i++) {
      final sa = a.nextServe(), sb = b.nextServe();
      expect([sa.pos, sa.vel, sa.omega], [sb.pos, sb.vel, sb.omega]);
    }
    final ba = BallPhysics()..position = first.pos..launch(first.vel, first.omega);
    final bb = BallPhysics()..position = first.pos..launch(first.vel, first.omega);
    for (var i = 0; i < 240; i++) {
      ba.step(T.physicsDt);
      bb.step(T.physicsDt);
      expect(ba.position, bb.position);
    }
  });

  test('serve dopadá do kop-zóny (10 seedů)', () {
    final gen = ServeGenerator(7);
    for (var i = 0; i < 10; i++) {
      final s = gen.nextServe();
      final ball = BallPhysics()..position = s.pos..launch(s.vel, s.omega);
      for (var t = 0; ball.bounceCount < 1 && t < maxTicks; t++) {
        ball.step(T.physicsDt);
      }
      final p = ball.position;
      expect(p.z > -3.2 && p.z < -0.5 && p.x.abs() < 1.0, isTrue,
          reason: 'serve $i dopadl mimo zónu: $p');
    }
  });
}
