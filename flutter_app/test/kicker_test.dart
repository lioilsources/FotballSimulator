// Procedurální fotbalista — póza musí dávat fyzikálně čitelnou zpětnou
// vazbu (kde nárt potkal míč) a být zrcadlová pro praváka/leváka.
import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/core/kicker.dart';
import 'package:fotball_simulator/core/tuning.dart';
import 'package:fotball_simulator/core/vec3.dart';

const ideal = Vec3(0.2, T.idealKickHeight, -1.8);

/// Postoj → nápřah → úder do bodu na plášti daného směrem [n] ze středu.
Kicker strikeAt(Foot foot, Vec3 n, {Vec3 ball = ideal}) {
  final k = Kicker(foot: foot)..onServe(ideal);
  for (var i = 0; i < 120; i++) {
    k.update(T.physicsDt);
  }
  k.windup();
  for (var i = 0; i < 40; i++) {
    k.update(T.physicsDt);
  }
  final u = n.normalized();
  k.strike(ball + u * T.ballRadius, u, const Vec3(0, 3, -30), 1);
  return k;
}

double dist(Vec3 a, Vec3 b) => (a - b).length;

void main() {
  test('postoj: pravák stojí vlevo od míče, za ním', () {
    final k = Kicker()..onServe(ideal);
    final p = k.pose();
    expect(p[Joint.pelvis]!.x, lessThan(ideal.x));
    expect(p[Joint.pelvis]!.z, greaterThan(ideal.z));
    expect(p[Joint.ankleL]!.y, closeTo(0.08, 1e-9), reason: 'nohy na zemi');
    expect(p[Joint.ankleR]!.y, closeTo(0.08, 1e-9));
  });

  test('délky kostí drží (IK)', () {
    final k = strikeAt(Foot.right, const Vec3(0, -0.12, 1));
    final p = k.pose();
    for (final (hip, knee, ankle) in [
      (Joint.hipL, Joint.kneeL, Joint.ankleL),
      (Joint.hipR, Joint.kneeR, Joint.ankleR),
    ]) {
      expect(dist(p[hip]!, p[knee]!), closeTo(T.kickerThigh, 1e-9));
      expect(dist(p[knee]!, p[ankle]!), closeTo(T.kickerShin, 1e-9));
    }
  });

  test('nápřah: pata kopací nohy jde dozadu nahoru', () {
    final k = Kicker()..onServe(ideal);
    final rest = k.pose()[Joint.ankleR]!;
    k.windup();
    for (var i = 0; i < 60; i++) {
      k.update(T.physicsDt);
    }
    final back = k.pose()[Joint.ankleR]!;
    expect(back.y, greaterThan(rest.y + 0.2));
    expect(back.z, greaterThan(rest.z));
    expect(k.pose()[Joint.ankleL]!.z, lessThan(rest.z), reason: 'stojná noha k míči');
  });

  test('úder: nárt na kontaktním bodě (freeze-frame snímek)', () {
    const n = Vec3(0, -0.12, 1);
    final k = strikeAt(Foot.right, n);
    final p = k.pose();
    final contact = ideal + n.normalized() * T.ballRadius;
    final instep = p[Joint.ankleR]!.lerp(p[Joint.toeR]!, 0.09 / T.kickerFootLen);
    expect(dist(instep, contact), lessThan(0.06));
    expect(k.swoosh, isNotNull);
  });

  test('pozdě (kontakt nad středem) = noha výš a trup přes míč', () {
    final low = strikeAt(Foot.right, const Vec3(0, -0.4, 1)).pose();
    final high = strikeAt(Foot.right, const Vec3(0, 0.5, 1)).pose();
    expect(high[Joint.ankleR]!.y, greaterThan(low[Joint.ankleR]!.y + 0.08));
    // trup: hlava víc vpředu (−z) vůči pánvi
    double lean(Map<Joint, Vec3> p) => p[Joint.pelvis]!.z - p[Joint.head]!.z;
    expect(lean(high), greaterThan(lean(low) + 0.1));
  });

  test('mimo dosah: kotník se přitáhne, noha se nepřetáhne', () {
    final k = strikeAt(Foot.right, const Vec3(0, 0, 1),
        ball: const Vec3(2.5, 0.55, -3.5));
    final p = k.pose();
    expect(dist(p[Joint.hipR]!, p[Joint.ankleR]!),
        lessThanOrEqualTo(T.kickerThigh + T.kickerShin));
  });

  test('levák = zrcadlo praváka kolem osy míče', () {
    const n = Vec3(0.3, -0.1, 1);
    final r = strikeAt(Foot.right, n);
    final l = strikeAt(Foot.left, Vec3(-n.x, n.y, n.z));
    Vec3 mirror(Vec3 v) => Vec3(2 * ideal.x - v.x, v.y, v.z);
    final pr = r.pose(), pl = l.pose();
    expect(dist(mirror(pr[Joint.pelvis]!), pl[Joint.pelvis]!), lessThan(1e-9));
    for (final (a, b) in [
      (Joint.kneeL, Joint.kneeR), (Joint.kneeR, Joint.kneeL),
      (Joint.toeR, Joint.toeL), (Joint.handL, Joint.handR), (Joint.head, Joint.head),
    ]) {
      expect(dist(mirror(pr[a]!), pl[b]!), lessThan(1e-9), reason: '$a ↔ $b');
    }
  });

  test('dokopnutí → návrat → postoj', () {
    final k = strikeAt(Foot.right, const Vec3(0, -0.12, 1));
    final contactAnkle = k.pose()[Joint.ankleR]!;
    for (var i = 0; i < (T.kickerFollowTime * 120).ceil(); i++) {
      k.update(T.physicsDt);
    }
    expect(k.phase, KickerPhase.recover);
    expect(k.pose()[Joint.ankleR]!.z, lessThan(contactAnkle.z), reason: 'noha prošla míčem');
    for (var i = 0; i < (T.kickerRecoverTime * 120).ceil() + 1; i++) {
      k.update(T.physicsDt);
    }
    expect(k.phase, KickerPhase.stance);
  });
}
