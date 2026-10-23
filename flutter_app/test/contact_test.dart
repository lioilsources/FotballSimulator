// Port tests/contact_test.gd — tabulkové případy contact modelu.
// Lokální rámec: -z = na bránu, +x doprava, +y nahoru. Topspin pro let -z
// = omega.x < 0, sidespin omega.y > 0 ⇒ Magnus +x.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/core/ball_physics.dart';
import 'package:fotball_simulator/core/contact_model.dart';
import 'package:fotball_simulator/core/tuning.dart';
import 'package:fotball_simulator/core/vec3.dart';

KickResult kick(double ox, double oy,
        {double curve = 0, double power = 1, double err = 0}) =>
    ContactModel.computeKick(Vec2(ox, oy), curve, power, err);

void main() {
  test('střed', () {
    final r = kick(0, 0);
    expect(r.hit, isTrue);
    expect(r.rating, Rating.perfect);
    expect(r.vel.z, lessThan(-25));
    expect(r.vel.x.abs(), lessThan(0.01));
    expect(r.omega.x, lessThan(-5), reason: 'mírný topspin ze zdvihu švihu');
    expect(r.omega.y.abs(), lessThan(0.01));
  });

  test('boční zásahy + zrcadlová symetrie', () {
    final right = kick(0.5, 0), left = kick(-0.5, 0);
    expect(right.vel.x, lessThan(-3));
    expect(right.omega.y, greaterThan(10));
    expect(left.vel.x, greaterThan(3));
    expect(left.omega.y, lessThan(-10));
    expect((right.vel.x + left.vel.x).abs(), lessThan(0.001));
    expect((right.omega.y + left.omega.y).abs(), lessThan(0.001));
  });

  test('pod míč: elevace + backspin', () {
    final center = kick(0, 0), under = kick(0, -0.5);
    expect(under.vel.y, greaterThan(center.vel.y + 5));
    expect(under.omega.x, greaterThan(3));
  });

  test('zakřivení swipu', () {
    expect(kick(0, 0, curve: 1).omega.y, lessThan(-20));
    expect(kick(0, 0, curve: -1).omega.y, greaterThan(20));
  });

  test('timing ratingy', () {
    expect(kick(0, 0, err: 0).rating, Rating.perfect);
    expect(kick(0, 0, err: 0.05).rating, Rating.good);
    expect(kick(0, 0, err: 0.10).rating, Rating.late);
    expect(kick(0, 0, err: -0.10).rating, Rating.early);
    final miss = kick(0, 0, err: 0.2);
    expect(miss.rating, Rating.miss);
    expect(miss.hit, isFalse);
    expect(miss.vel, Vec3.zero);
  });

  test('pozdě = nedoletí mechanicky (§3.4/6)', () {
    final onTime = kick(0, -0.3), late = kick(0, -0.3, err: 0.09);
    final elevOn = math.atan2(onTime.vel.y, -onTime.vel.z);
    final elevLate = math.atan2(late.vel.y, -late.vel.z);
    expect(elevLate, lessThan(elevOn - 0.05));
    expect(late.omega.x / late.vFoot, lessThan(onTime.omega.x / onTime.vFoot - 0.1));
    expect(late.vel.length, lessThan(onTime.vel.length * 0.5));
  });

  test('síla škáluje rychlost', () {
    expect(kick(0, 0, power: 0.5).vel.length, lessThan(kick(0, 0).vel.length * 0.6));
  });

  test('perfektní nízký volej projde bránou', () {
    final k = kick(0, -0.12);
    final ball = BallPhysics()
      ..position = const Vec3(0, T.idealKickHeight, -1.8)
      ..launch(k.vel, k.omega);
    Vec3? cross;
    for (var i = 0; ball.flying && i < 120 * 5; i++) {
      final prev = ball.position;
      ball.step(T.physicsDt);
      if (prev.z > -T.goalDistance && ball.position.z <= -T.goalDistance) {
        cross = ball.position;
        break;
      }
    }
    expect(cross, isNotNull, reason: 'volej doletí k bráně');
    expect(cross!.x.abs(), lessThan(T.goalHalfWidth));
    expect(cross.y, inExclusiveRange(0, T.goalHeight));
  });

  // B2 (ROADMAP): contact model nesmí zahodit příchozí rychlost míče.
  test('příchozí rychlost míče', () {
    const incoming = Vec3(0, -2, 4);
    const aim = Vec2(0, -0.12);
    final still = ContactModel.computeKick(aim, 0, 1, 0);
    final strong = ContactModel.computeKick(aim, 0, 1, 0, incoming);
    expect(strong.vel.z, lessThan(-25));
    expect(strong.vel.length, greaterThan(still.vel.length + 0.5));
    expect(ContactModel.computeKick(aim, 0, 1, 0, Vec3.zero).vel, still.vel);

    // pozdní tečování: míč nezůstane viset, jde do země, neletí na bránu
    final late = ContactModel.computeKick(aim, 0, 1, 0.09, incoming);
    expect(late.vel.length, greaterThan(2));
    expect(late.vel.y, lessThan(-1.5));
    expect(late.vel.z, greaterThan(-5));

    // míč utíká rychleji než nárt ⇒ beze změny
    const fleeing = Vec3(0, 0, -10);
    expect(ContactModel.computeKick(Vec2.zero, 0, 0.1, 0, fleeing).vel, fleeing);

    final miss = ContactModel.computeKick(aim, 0, 1, 0.2, incoming);
    expect(miss.hit, isFalse);
    expect(miss.vel, incoming);
  });
}
