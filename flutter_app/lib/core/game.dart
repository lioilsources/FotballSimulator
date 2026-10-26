import 'dart:math' as math;

import 'ball_physics.dart';
import 'contact_model.dart';
import 'serve_generator.dart';
import 'tuning.dart';
import 'vec3.dart';

enum GameState { serve, kickWindow, flight, result }

/// Freeze-frame kontaktu (§5.3): kontaktní bod + vektor výkopu ve světě.
class FreezeFrame {
  final Vec3 contact, vel;
  double remaining; // s reálného času
  FreezeFrame(this.contact, this.vel, this.remaining);
}

/// Herní FSM (port `game_state.gd`, VOLLEY_PLAN.md §2):
/// SERVE → KICK_WINDOW → FLIGHT → RESULT. Čistý Dart — UI jen čte stav
/// (HUD texty, freeze, trail) a volá [update] / [onKickReleased].
class Game {
  final BallPhysics ball = BallPhysics();
  final ServeGenerator _serveGen;
  final List<Vec3> trail = [];

  GameState state = GameState.serve;
  bool assist = T.assistDefault;
  double timeScale = 1.0;
  bool swipeEnabled = true;

  // HUD
  String kickText = '';
  double kickTextAge = double.infinity; // s reálného času od zobrazení
  String resultText = '';
  int resultColor = 0xFFFFFFFF;
  FreezeFrame? freeze;

  double serveTime = 0.0; // herní čas od začátku serve (nezávislý na timeScale)
  double tIdeal = 0.0; // ideální okamžik kontaktu (z pre-simulace)
  bool _swung = false; // jeden švih na serve
  bool _resultReported = false;
  double _resultTimer = 0.0;
  double _accum = 0.0;

  Game({int seed = T.serveSeed}) : _serveGen = ServeGenerator(seed) {
    ball.onBounced = _onBallBounced;
    ball.onStopped = _onBallStopped;
    _serve();
  }

  void _serve() {
    state = GameState.serve;
    _swung = false;
    _resultReported = false;
    serveTime = 0.0;
    swipeEnabled = true;
    resultText = '';
    trail.clear();
    final s = _serveGen.nextServe();
    ball.position = s.pos;
    ball.launch(s.vel, s.omega);
    tIdeal = presimIdealTime(s);
  }

  /// Snímek reálného času: freeze-frame, slow-mo, fixed 120 Hz ticky.
  void update(double realDt) {
    kickTextAge += realDt;
    final f = freeze;
    if (f != null) {
      f.remaining -= realDt;
      if (f.remaining > 0) return; // celý svět stojí
      freeze = null;
    }
    // strop proti spirále smrti po návratu z pozadí
    _accum += math.min(realDt, 0.1) * timeScale;
    while (_accum >= T.physicsDt) {
      _accum -= T.physicsDt;
      tick(T.physicsDt);
      if (freeze != null) {
        _accum = 0;
        break;
      }
    }
  }

  /// Jeden fyzikální tick (veřejné kvůli testům).
  void tick(double dt) {
    final prevPos = ball.position;
    ball.step(dt);
    serveTime += dt;
    if (ball.flying) {
      trail.add(ball.position);
      if (trail.length > T.trailMaxPoints) trail.removeAt(0);
    }

    switch (state) {
      case GameState.serve:
      case GameState.kickWindow:
        // druhý dopad = šance pryč (volej se kope před ním)
        if (ball.bounceCount >= 2) {
          _finishServe(_swung ? 'MIMO' : 'POZDĚ', 0xFFFF9933);
        }
      case GameState.flight:
        if (!_resultReported) _checkGoalCrossing(prevPos);
        // míč daleko za bránou už nemá co ukázat
        if (ball.position.z < -(T.goalDistance + T.flightEndBeyondGoal)) {
          ball.stop();
          _finishServe('', 0xFFFFFFFF);
        }
      case GameState.result:
        _resultTimer -= dt;
        if (_resultTimer <= 0) _serve();
    }
  }

  // ── timing okno ───────────────────────────────────────────────

  /// Pre-simulace serve: po prvním odskoku míč stoupá → vrchol → klesá;
  /// ideál = průchod idealKickHeight při klesání (§3.5). Slabý odskok
  /// (nedosáhne té výšky) → ideál = vrchol odskoku.
  static double presimIdealTime(Serve s) {
    final scratch = BallPhysics()
      ..position = s.pos
      ..launch(s.vel, s.omega);
    var t = 0.0, apexT = 0.0, apexH = 0.0;
    while (t < 8.0 && scratch.flying && scratch.bounceCount < 2) {
      scratch.step(T.physicsDt);
      t += T.physicsDt;
      if (scratch.bounceCount == 1) {
        if (scratch.position.y > apexH) {
          apexH = scratch.position.y;
          apexT = t;
        }
        if (scratch.vel.y < 0 && scratch.position.y <= T.idealKickHeight) {
          return t;
        }
      }
    }
    return apexT > 0 ? apexT : t;
  }

  void _onBallBounced(Vec3 pos, double speed) {
    if (state == GameState.serve && ball.bounceCount == 1) {
      state = GameState.kickWindow;
    }
  }

  bool get kickable =>
      (state == GameState.serve || state == GameState.kickWindow) && !_swung;

  // ── swipe → kop ───────────────────────────────────────────────

  void onSwipeStarted() {
    if (kickable && assist) timeScale = T.assistSlowmo;
  }

  void onSwipeCanceled() => timeScale = 1.0;

  void onKickReleased(Vec2 offset, double curve, double power) {
    timeScale = 1.0;
    if (!kickable) return;
    _swung = true;
    swipeEnabled = false;

    final err = serveTime - tIdeal;

    // lokální rámec kopu (-z na bránu) ⇄ svět
    final fwd = (const Vec3(0, 0, -T.goalDistance) - ball.position)
        .withY(0)
        .normalized();
    final right = fwd.cross(Vec3.up);
    final ballVelLocal =
        Vec3(ball.vel.dot(right), ball.vel.y, -ball.vel.dot(fwd));

    final res = ContactModel.computeKick(offset, curve, power, err, ballVelLocal);
    final errMs = (err * 1000).round();

    if (!res.hit) {
      // vzduch — míč letí dál, serve uzavře druhý dopad
      _showKickText('VZDUCH! (${_signed(errMs)} ms)');
      return;
    }

    Vec3 toWorld(Vec3 v) => right * v.x + Vec3.up * v.y - fwd * v.z;
    final vel = toWorld(res.vel);
    final omega = toWorld(res.omega);
    final contactWorld = ball.position + toWorld(res.contactDir) * T.ballRadius;

    trail.clear();
    ball.launch(vel, omega);
    state = GameState.flight;
    _resultReported = false;
    _showKickText('${(vel.length * 3.6).round()} km/h · '
        '${(omega.length / (2 * math.pi)).toStringAsFixed(1)} ot/s · '
        '${res.rating.name.toUpperCase()} (${_signed(errMs)} ms)');
    freeze = FreezeFrame(contactWorld, vel, T.freezeTime);
  }

  // ── debug kopy (Fáze 0, klávesy 1/2/3) ────────────────────────

  void debugKick(Vec3 spin) {
    if (state == GameState.flight) return;
    state = GameState.flight;
    _resultReported = false;
    _swung = true;
    swipeEnabled = false;
    trail.clear();
    final dir = (const Vec3(0, 0, -T.goalDistance) - ball.position)
        .withY(0)
        .normalized();
    final angle = T.debugKickAngleDeg * math.pi / 180;
    ball.launch(
      dir * (T.debugKickSpeed * math.cos(angle)) +
          Vec3.up * (T.debugKickSpeed * math.sin(angle)),
      spin,
    );
  }

  // ── výsledky ──────────────────────────────────────────────────

  /// Průlet rovinou brány → GÓL / MIMO (tyč a síť řeší Fáze 2).
  void _checkGoalCrossing(Vec3 prev) {
    const planeZ = -T.goalDistance;
    final cur = ball.position;
    if (prev.z > planeZ && cur.z <= planeZ) {
      final t = (planeZ - prev.z) / (cur.z - prev.z);
      final crossX = prev.x + (cur.x - prev.x) * t;
      final crossY = prev.y + (cur.y - prev.y) * t;
      _resultReported = true;
      if (crossX.abs() < T.goalHalfWidth && crossY < T.goalHeight) {
        _showResult('GÓL!', 0xFF4DFF66);
      } else {
        _showResult('MIMO', 0xFFFF594D);
      }
    }
  }

  void _onBallStopped() {
    if (state == GameState.flight && !_resultReported) {
      _showResult('NEDOLETĚL', 0xFFFF9933);
    }
    _finishServe('', 0xFFFFFFFF);
  }

  /// Uzavře rozehrávku (s volitelnou hláškou) a po pauze rozehraje další míč.
  void _finishServe(String msg, int color) {
    if (state == GameState.result) return;
    state = GameState.result;
    swipeEnabled = false;
    timeScale = 1.0;
    if (msg.isNotEmpty) _showResult(msg, color);
    _resultTimer = T.resultPause;
  }

  void _showResult(String text, int color) {
    resultText = text;
    resultColor = color;
  }

  void _showKickText(String text) {
    kickText = text;
    kickTextAge = 0;
  }

  static String _signed(int v) => v >= 0 ? '+$v' : '$v';
}
