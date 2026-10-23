import 'dart:math' as math;

import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../core/game.dart';
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
    if (!ballBehindGoal) _ballAndTrail(canvas, cam);
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

  void _ballAndTrail(Canvas canvas, Camera cam) {
    final ball = game.ball;
    if (cam.isBehind(ball.position)) return;

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
