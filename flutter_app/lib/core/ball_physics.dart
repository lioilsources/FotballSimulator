import 'dart:math' as math;

import 'tuning.dart';
import 'vec3.dart';

/// Vlastní integrace letu míče (port `ball_physics.gd`, VOLLEY_PLAN.md
/// §3.2–3.3). Semi-implicitní Euler na fixed ticku 120 Hz. Žádné závislosti
/// na Flutteru — testovatelné čistým `dart test`.
class BallPhysics {
  Vec3 position = Vec3.zero;
  Vec3 vel = Vec3.zero;
  Vec3 omega = Vec3.zero; // spin v rad/s (osa × velikost)
  bool flying = false; // false = míč čeká (serve/výsledek)
  int bounceCount = 0; // odskoky od posledního launch()
  final Basis basis = Basis(); // vizuální orientace (spin dots)

  void Function(Vec3 pos, double impactSpeed)? onBounced;
  void Function()? onStopped;

  bool _rolling = false;

  void launch(Vec3 startVel, Vec3 spin) {
    vel = startVel;
    omega = spin;
    flying = true;
    _rolling = false;
    bounceCount = 0;
  }

  void stop() {
    vel = Vec3.zero;
    omega = Vec3.zero;
    flying = false;
    _rolling = false;
  }

  void step(double delta) {
    if (!flying) return;

    if (_rolling) {
      _roll(delta);
      return;
    }

    // síly: gravitace + drag + Magnus (§3.2)
    final vLen = vel.length;
    final drag = vel * (-0.5 * T.rho * T.cd * T.ballArea * vLen);
    final magnus = omega.cross(vel) * T.sCoeff;
    final accel = T.gravity + (drag + magnus) / T.ballMass;

    vel += accel * delta;
    position += vel * delta;
    omega *= math.exp(-T.spinDecay * delta);
    _spinVisual(delta);

    if (position.y < T.ballRadius && vel.y < 0.0) _bounce();
  }

  /// Odskok od země (§3.3): restituce + tření + přenos spinu do xz.
  void _bounce() {
    position = position.withY(T.ballRadius);
    final impact = vel.y.abs();
    var vy = -T.restitution * vel.y;

    // rychlost povrchu míče v kontaktním bodě (dole) — topspin táhne dopředu
    const contactR = Vec3(0, -T.ballRadius, 0);
    final surface = omega.cross(contactR);
    final xz = Vec3(vel.x, 0, vel.z) * (1.0 - T.groundFriction) -
        surface * T.bounceSpinTransfer;
    omega *= T.bounceSpinRetain;

    bounceCount += 1;
    final rolling = vy < T.bounceMinVy;
    if (rolling) vy = 0.0;
    vel = Vec3(xz.x, vy, xz.z);
    onBounced?.call(position, impact);
    if (rolling) _rolling = true;
  }

  /// Kutálení: exponenciální útlum, pod stopSpeed míč usne.
  void _roll(double delta) {
    vel *= math.exp(-T.rollFriction * delta);
    position = (position + vel * delta).withY(T.ballRadius);
    omega *= math.exp(-T.rollFriction * delta);
    _spinVisual(delta);
    if (vel.length < T.stopSpeed) {
      stop();
      onStopped?.call();
    }
  }

  /// Vizuální rotace — hráč čte faleš z míče, ne z HUD.
  void _spinVisual(double delta) {
    final w = omega.length;
    if (w > 0.001) basis.rotate(omega / w, w * delta);
  }
}
