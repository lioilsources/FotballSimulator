import 'dart:math' as math;

import 'tuning.dart';
import 'vec3.dart';

enum Rating { perfect, good, early, late, miss }

/// Výsledek kontaktu nárt × míč (lokální rámec kopu).
class KickResult {
  final bool hit;
  final Rating rating;
  final Vec3 vel;
  final Vec3 omega;
  final double timingQuality;
  final double vFoot;
  final Vec3 contactDir;

  const KickResult({
    required this.hit,
    required this.rating,
    required this.vel,
    required this.omega,
    required this.timingQuality,
    required this.vFoot,
    required this.contactDir,
  });
}

/// ⭐ Jádro hry (port `contact_model.gd`, VOLLEY_PLAN.md §3.4): čistá funkce
/// nárt × míč → rychlost + spin. Lokální rámec kopu: -z = směr na bránu,
/// +x = doprava (z pohledu hráče), +y = nahoru. Převod do světa dělá Game.
abstract final class ContactModel {
  /// [contactOffset]: kde na míči (-1..1 od středu, +x vpravo, +y nahoře);
  /// [swingCurve]: zakřivení swipu -1..1 (+ = oblouk doprava);
  /// [power]: 0..1 z rychlosti swipu;
  /// [timingError]: sekundy od ideálního okamžiku, kladné = pozdě;
  /// [ballVel]: rychlost míče před kontaktem v lokálním rámci (serve míč
  /// přilétá +z). Impuls vychází z relativní rychlosti nárt−míč, takže
  /// slabý/pozdní kontakt míč jen tečuje místo aby ho zastavil ve vzduchu.
  static KickResult computeKick(
      Vec2 contactOffset, double swingCurve, double power, double timingError,
      [Vec3 ballVel = Vec3.zero]) {
    final rating = rateTiming(timingError);
    if (rating == Rating.miss) {
      // nárt mine — míč letí dál beze změny
      return KickResult(
        hit: false, rating: rating, vel: ballVel, omega: Vec3.zero,
        timingQuality: 0, vFoot: 0, contactDir: Vec3.zero,
      );
    }

    // §3.4/6 — pozdě: nárt trefí míč VÝŠ na plášti → topspin, nízká dráha;
    // brzy symetricky POD míč → vyšší, slabší oblouk.
    var off = Vec2(
      contactOffset.x,
      contactOffset.y +
          T.lateShift * (timingError / T.timingWindow).clamp(-1.0, 1.0),
    ).limitLength(0.95); // kontakt musí zůstat na míči

    // 1–2: kvalita timingu → rychlost nártu
    final timingQuality =
        math.exp(-math.pow(timingError / T.timingSigma, 2).toDouble());
    final vFoot = T.footSpeedMax * power * timingQuality;

    // 3: kontaktní bod na přivrácené polokouli (+z strana), normála skrz střed
    final u = Vec3(off.x, off.y, math.sqrt(math.max(0.0, 1.0 - off.lengthSquared)))
        .normalized();
    final n = -u;

    // dráha nártu: dopředu s mírným zdvihem; energii předává jen složka
    // podél normály — extrémní offsety = slabší, ale točivější zásah
    final swingDir = const Vec3(0, T.swingLift, -1).normalized();
    final footNormalSpeed = vFoot * math.max(0.0, swingDir.dot(n));

    // 4: impuls → rychlost míče (§3.4/4). Rozhoduje rychlost, kterou se
    // nárt a míč k sobě podél normály blíží; míč letící proti nártu dostane
    // o to víc, míč prchající před nártem (pomalý švih) skoro nic.
    final closingSpeed = math.max(0.0, footNormalSpeed - ballVel.dot(n));
    final vel =
        ballVel + n * (closingSpeed * T.corKick * T.footMassEff / T.ballMass);

    // 5: faleš — osa spinu u × t (odvozeno z τ = r×F). Zásah vpravo → míč
    // letí doleva se spinem, který ho Magnusem vrací doprava.
    final tVec = swingDir - n * swingDir.dot(n);
    var omega = u.cross(tVec) * (T.spinTransfer * vFoot);
    // zakřivení swipu: oblouk doprava (+) ⇒ faleš doprava ⇒ spin kolem -y
    omega += Vec3.down * (T.curveSpin * vFoot * swingCurve);

    return KickResult(
      hit: true, rating: rating, vel: vel, omega: omega,
      timingQuality: timingQuality, vFoot: vFoot, contactDir: u,
    );
  }

  /// §3.5: perfect < 30 ms, good < 70 ms, late/early < 120 ms, jinak miss.
  static Rating rateTiming(double timingError) {
    final e = timingError.abs();
    if (e < T.ratingPerfect) return Rating.perfect;
    if (e < T.ratingGood) return Rating.good;
    if (e < T.ratingLateEarly) {
      return timingError > 0 ? Rating.late : Rating.early;
    }
    return Rating.miss;
  }
}
