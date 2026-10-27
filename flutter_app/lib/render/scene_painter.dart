import 'dart:math' as math;

import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../core/game.dart';
import '../core/kicker.dart';
import '../core/tuning.dart';
import '../core/vec3.dart';
import 'camera.dart';

/// Vykreslení 3D scény (hřiště, brána, míč, trail, freeze-frame) přes
/// vlastní perspektivní projekci — Flutter nemá 3D, scéna je jednoduchá.
class ScenePainter extends CustomPainter {
  final Game game;
  ScenePainter(this.game, Listenable repaint) : super(repaint: repaint);

  static const _grassA = Color(0xFF2A7332);
  static const _grassB = Color(0xFF2F7D37);
  static const _line = Color(0xFFE6EDE6);

  @override
  void paint(Canvas canvas, Size size) {
    final cam = Camera(size);
    _sky(canvas, size, cam);
    _grass(canvas, size, cam);
    _pitchLines(canvas, cam);

    final ballBehindGoal = game.ball.position.z < -T.goalDistance;
    if (ballBehindGoal) _ballAndTrail(canvas, cam);
    _goal(canvas, cam);
    _kickerShadow(canvas, cam);
    if (!ballBehindGoal) _ballAndTrail(canvas, cam, kicker: true);
    if (ballBehindGoal) _kicker(canvas, cam, const []);
    _freezeFrame(canvas, cam);
  }

  // ── prostředí ─────────────────────────────────────────────────

  void _sky(Canvas canvas, Size size, Camera cam) {
    final h = cam.horizonY;
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, h + 1),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF406BA8), Color(0xFFA6B8C7)],
        ).createShader(Rect.fromLTRB(0, 0, size.width, h)),
    );
  }

  void _grass(Canvas canvas, Size size, Camera cam) {
    canvas.drawRect(
        Rect.fromLTRB(0, cam.horizonY, size.width, size.height),
        Paint()..color = const Color(0xFF235F2A));
    // pruhy sekání — hlavní hloubkové vodítko
    const stripe = 4.0;
    for (var i = 0; i < 20; i++) {
      final zNear = 3.0 - i * stripe;
      final zFar = zNear - stripe;
      final path = Path()
        ..addPolygon([
          cam.project(Vec3(-30, 0, zNear)),
          cam.project(Vec3(30, 0, zNear)),
          cam.project(Vec3(30, 0, zFar)),
          cam.project(Vec3(-30, 0, zFar)),
        ], true);
      canvas.drawPath(path, Paint()..color = i.isEven ? _grassA : _grassB);
    }
  }

  /// Čára na zemi rozsekaná na kusy, aby tloušťka sledovala perspektivu.
  void _groundLine(Canvas canvas, Camera cam, Vec3 a, Vec3 b) {
    final n = math.max(1, ((b - a).length / 1.0).ceil());
    final paint = Paint()
      ..color = _line
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final p0 = a + (b - a) * (i / n);
      final p1 = a + (b - a) * ((i + 1) / n);
      paint.strokeWidth = math.max(1.0, cam.scaleAt((p0 + p1) * 0.5, 0.12));
      canvas.drawLine(cam.project(p0), cam.project(p1), paint);
    }
  }

  void _pitchLines(Canvas canvas, Camera cam) {
    const g = -T.goalDistance;
    // brankové čáry, pokutové a malé území (rozměry dle pravidel)
    _groundLine(canvas, cam, const Vec3(-25, 0, g), const Vec3(25, 0, g));
    for (final (half, depth) in [(20.16, 16.5), (9.16, 5.5)]) {
      final front = g + depth;
      _groundLine(canvas, cam, Vec3(-half, 0, g), Vec3(-half, 0, front));
      _groundLine(canvas, cam, Vec3(half, 0, g), Vec3(half, 0, front));
      _groundLine(canvas, cam, Vec3(-half, 0, front), Vec3(half, 0, front));
    }
    // penaltový bod
    final spot = const Vec3(0, 0, g + 11);
    final sp = cam.project(spot);
    canvas.drawOval(
      Rect.fromCenter(
          center: sp,
          width: cam.scaleAt(spot, 0.3),
          height: cam.scaleAt(spot, 0.3) * 0.3),
      Paint()..color = _line,
    );
  }

  void _goal(Canvas canvas, Camera cam) {
    const z = -T.goalDistance;
    const zb = z - T.goalDepth;
    const w = T.goalHalfWidth + T.goalPostRadius;
    const h = T.goalHeight + T.goalPostRadius;

    // síť: zadní stěna, boky, střecha
    final net = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.0;
    const step = 0.4;
    for (var x = -w; x <= w + 1e-6; x += step) {
      canvas.drawLine(cam.project(Vec3(x, 0, zb)), cam.project(Vec3(x, h, zb)), net);
      canvas.drawLine(cam.project(Vec3(x, h, z)), cam.project(Vec3(x, h, zb)), net);
    }
    for (var y = 0.0; y <= h + 1e-6; y += step) {
      canvas.drawLine(cam.project(Vec3(-w, y, zb)), cam.project(Vec3(w, y, zb)), net);
      for (final sx in [-w, w]) {
        canvas.drawLine(cam.project(Vec3(sx, y, z)), cam.project(Vec3(sx, y, zb)), net);
      }
    }
    for (var d = 0.0; d <= T.goalDepth + 1e-6; d += step) {
      final zz = z - d;
      canvas.drawLine(cam.project(Vec3(-w, h, zz)), cam.project(Vec3(w, h, zz)), net);
      for (final sx in [-w, w]) {
        canvas.drawLine(cam.project(Vec3(sx, 0, zz)), cam.project(Vec3(sx, h, zz)), net);
      }
    }

    // tyče a břevno
    final frame = Paint()
      ..color = const Color(0xFFF2F2F2)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, cam.scaleAt(const Vec3(0, 1, z), 0.12));
    final path = Path()
      ..moveTo(cam.project(const Vec3(-w, 0, z)).dx, cam.project(const Vec3(-w, 0, z)).dy)
      ..lineTo(cam.project(const Vec3(-w, h, z)).dx, cam.project(const Vec3(-w, h, z)).dy)
      ..lineTo(cam.project(const Vec3(w, h, z)).dx, cam.project(const Vec3(w, h, z)).dy)
      ..lineTo(cam.project(const Vec3(w, 0, z)).dx, cam.project(const Vec3(w, 0, z)).dy);
    canvas.drawPath(path, frame..style = PaintingStyle.stroke);
  }

  // ── míč ───────────────────────────────────────────────────────

  /// Stín, trail a míč; s [kicker] se míč řadí do hloubky s fotbalistou.
  void _ballAndTrail(Canvas canvas, Camera cam, {bool kicker = false}) {
    final ball = game.ball;
    if (cam.isBehind(ball.position)) {
      if (kicker) _kicker(canvas, cam, const []);
      return;
    }

    // stín — slábne s výškou
    final ground = ball.position.withY(0.005);
    final shadowR = cam.scaleAt(ground, T.ballRadius);
    final lift = (ball.position.y - T.ballRadius).clamp(0.0, 4.0);
    canvas.drawOval(
      Rect.fromCenter(
          center: cam.project(ground), width: shadowR * 2.2, height: shadowR * 0.7),
      Paint()..color = Color.fromRGBO(0, 0, 0, 0.35 * (1 - lift / 4.0)),
    );

    // debug trail letu
    if (game.trail.length >= 2) {
      final pts = [
        for (final p in game.trail)
          if (!cam.isBehind(p)) cam.project(p)
      ];
      canvas.drawPoints(
        PointMode.polygon,
        pts,
        Paint()
          ..color = const Color(0xCCFF7319)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }

    final sphere = (cam.depth(ball.position), () => _ballSphere(canvas, cam));
    if (kicker) {
      _kicker(canvas, cam, [sphere]);
    } else {
      sphere.$2();
    }
  }

  void _ballSphere(Canvas canvas, Camera cam) {
    final ball = game.ball;
    final c = cam.project(ball.position);
    final r = math.max(2.0, cam.scaleAt(ball.position, T.ballRadius));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: const [Color(0xFFFFFFFF), Color(0xFFDADADA), Color(0xFF8C8C8C)],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // spin dots (tělesové osy +z, +x jako v ball.tscn) — viditelné jen
    // na přivrácené polokouli
    final toCam = (T.cameraPos - ball.position).normalized();
    final dotR = math.max(1.0, cam.scaleAt(ball.position, 0.028));
    for (final axis in [ball.basis.z, ball.basis.x]) {
      final facing = axis.dot(toCam);
      if (facing <= 0.05) continue;
      final p = cam.project(ball.position + axis * 0.095);
      canvas.drawCircle(
          p, dotR, Paint()..color = Color.fromRGBO(26, 26, 31, 0.4 + 0.5 * facing));
    }
  }

  // ── fotbalista ────────────────────────────────────────────────

  static const _skin = Color(0xFFE0AC86);
  static const _jersey = Color(0xFFC8302A);
  static const _jerseyDark = Color(0xFF9E2420);
  static const _shorts = Color(0xFFF2F2F2);
  static const _sock = Color(0xFFC8302A);
  static const _boot = Color(0xFF1C1C1F);
  static const _hair = Color(0xFF3A2A1E);

  void _kickerShadow(Canvas canvas, Camera cam) {
    final pose = game.kicker.pose();
    for (final j in [Joint.pelvis, Joint.ankleL, Joint.ankleR]) {
      final g = pose[j]!.withY(0.004);
      final w = cam.scaleAt(g, j == Joint.pelvis ? 0.32 : 0.14);
      final lift = j == Joint.pelvis ? 0.0 : (pose[j]!.y - 0.08).clamp(0.0, 0.8);
      canvas.drawOval(
        Rect.fromCenter(center: cam.project(g), width: w * 2, height: w * 0.6),
        Paint()
          ..color = Color.fromRGBO(
              0, 0, 0, 0.28 * (1 - lift / 0.8) * game.kicker.opacity),
      );
    }
  }

  /// Fotbalista: kosti jako tlusté čáry s perspektivní tloušťkou, trup jako
  /// polygon; vše (i [extra] = míč) seřazené odzadu dopředu.
  void _kicker(Canvas canvas, Camera cam, List<(double, void Function())> extra) {
    final k = game.kicker;
    final pose = k.pose();
    final items = <(double, void Function())>[...extra];
    // průhlednost po částech (překryvy končetin prosvítají — u ducha nevadí)
    Color fade(Color base) => base.withValues(alpha: base.a * k.opacity);

    void limb(Joint a, Joint b, double width, Color color, {Color? top, double split = 0}) {
      final pa = pose[a]!, pb = pose[b]!;
      if (cam.isBehind(pa) || cam.isBehind(pb)) return;
      items.add((cam.depth((pa + pb) * 0.5), () {
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(2.0, cam.scaleAt((pa + pb) * 0.5, width));
        if (top != null && split > 0) {
          final m = pa.lerp(pb, split);
          canvas.drawLine(cam.project(pa), cam.project(m), paint..color = fade(top));
          canvas.drawLine(cam.project(m), cam.project(pb), paint..color = fade(color));
        } else {
          canvas.drawLine(cam.project(pa), cam.project(pb), paint..color = fade(color));
        }
      }));
    }

    // nohy: stehno (trenýrky → kůže), holeň (štulpna), bota
    for (final (hip, knee, ankle, toe) in [
      (Joint.hipL, Joint.kneeL, Joint.ankleL, Joint.toeL),
      (Joint.hipR, Joint.kneeR, Joint.ankleR, Joint.toeR),
    ]) {
      limb(hip, knee, 0.15, _skin, top: _shorts, split: 0.55);
      limb(knee, ankle, 0.11, _sock, top: _skin, split: 0.2);
      limb(ankle, toe, 0.095, _boot);
    }
    // ruce: rukáv → kůže
    for (final (sh, el, ha) in [
      (Joint.shoulderL, Joint.elbowL, Joint.handL),
      (Joint.shoulderR, Joint.elbowR, Joint.handR),
    ]) {
      limb(sh, el, 0.095, _skin, top: _jersey, split: 0.5);
      limb(el, ha, 0.08, _skin);
    }

    // trup: dres (ramena → boky), trenýrky (boky)
    final shL = pose[Joint.shoulderL]!, shR = pose[Joint.shoulderR]!;
    final hipL = pose[Joint.hipL]!, hipR = pose[Joint.hipR]!;
    final waistL = hipL.lerp(shL, 0.12) + const Vec3(-0.04, 0, 0);
    final waistR = hipR.lerp(shR, 0.12) + const Vec3(0.04, 0, 0);
    items.add((cam.depth(pose[Joint.pelvis]!.lerp(pose[Joint.neck]!, 0.5)), () {
      final torso = Path()
        ..addPolygon([
          for (final p in [shL - const Vec3(0.03, 0, 0), shR + const Vec3(0.03, 0, 0), waistR, waistL])
            cam.project(p)
        ], true);
      canvas.drawPath(torso, Paint()..color = fade(_jersey));
      // číslo na zádech — čitelná orientace hráče
      final back = pose[Joint.pelvis]!.lerp(pose[Joint.neck]!, 0.6) + const Vec3(0, 0, 0.05);
      final h = cam.scaleAt(back, 0.18);
      final tp = TextPainter(
        text: TextSpan(
            text: '10',
            style: TextStyle(color: fade(_shorts), fontSize: h, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, cam.project(back) - Offset(tp.width / 2, tp.height / 2));
      final shorts = Path()
        ..addPolygon([
          for (final p in [
            waistL, waistR,
            hipR + const Vec3(0.05, -0.12, 0), hipL + const Vec3(-0.05, -0.12, 0),
          ])
            cam.project(p)
        ], true);
      canvas.drawPath(shorts, Paint()..color = fade(_shorts));
      // límec
      canvas.drawLine(cam.project(shL), cam.project(shR),
          Paint()
            ..color = fade(_jerseyDark)
            ..strokeWidth = math.max(1.0, cam.scaleAt(pose[Joint.neck]!, 0.03)));
    }));

    // hlava (zezadu = vlasy) + krk
    final head = pose[Joint.head]!;
    limb(Joint.neck, Joint.head, 0.09, _skin);
    items.add((cam.depth(head) - 0.01, () {
      final c = cam.project(head);
      final r = cam.scaleAt(head, T.kickerHeadRadius);
      canvas.drawCircle(c, r, Paint()..color = fade(_skin));
      canvas.drawCircle(c - Offset(0, r * 0.12), r * 0.97, Paint()..color = fade(_hair));
    }));

    // stopa švihu (nápřah → kontakt)
    final sw = k.swoosh;
    if (sw != null) {
      items.add((cam.depth(sw.to) - 0.05, () {
        final mid = sw.from.lerp(sw.to, 0.5) + const Vec3(0, -0.12, 0);
        final a = cam.project(sw.from), m = cam.project(mid), b = cam.project(sw.to);
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(m.dx * 2 - (a.dx + b.dx) / 2, m.dy * 2 - (a.dy + b.dy) / 2, b.dx, b.dy);
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, 0.55 * (1 - sw.age))
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = math.max(2.0, cam.scaleAt(sw.to, 0.12)),
        );
      }));
    }

    items.sort((a, b) => b.$1.compareTo(a.$1)); // daleko → blízko
    for (final (_, draw) in items) {
      draw();
    }
  }

  /// Freeze-frame (§5.3): kontaktní bod + vektor výkopu se šipkou.
  void _freezeFrame(Canvas canvas, Camera cam) {
    final f = game.freeze;
    if (f == null || cam.isBehind(f.contact)) return;
    final p = cam.project(f.contact);
    final tip = cam.project(f.contact + f.vel * 0.04);
    const yellow = Color(0xFFFFE633);
    final arrow = Paint()
      ..color = yellow
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p, tip, arrow);
    final d = tip - p;
    if (d.distance > 0) {
      final dir = d / d.distance;
      final side = Offset(-dir.dy, dir.dx);
      canvas.drawLine(tip, tip - dir * 12 + side * 7, arrow);
      canvas.drawLine(tip, tip - dir * 12 - side * 7, arrow);
    }
    const red = Color(0xFFFF4033);
    canvas.drawCircle(p, 7, Paint()..color = red);
    canvas.drawCircle(
        p,
        13,
        Paint()
          ..color = red.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant ScenePainter old) => false;
}
