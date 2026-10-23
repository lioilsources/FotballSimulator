import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/game.dart';
import '../core/tuning.dart';
import '../core/vec3.dart';
import '../render/scene_painter.dart';
import 'swipe_input.dart';

/// Hlavní obrazovka: Ticker → Game.update, raw pointer eventy → swipe,
/// CustomPaint scéna + overlay míč + HUD texty.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final Game _game = Game();
  final SwipeTracker _swipe = SwipeTracker();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final FocusNode _focus = FocusNode();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int? _pointer;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _game.update(dt);
    if (!_game.swipeEnabled && _swipe.tracking) _swipe.cancel();
    _frame.value++;
  }

  // ── vstup ─────────────────────────────────────────────────────

  void _onDown(PointerDownEvent e, Size size, double bottomInset) {
    if (_pointer != null || !_game.swipeEnabled) return;
    if (_swipe.start(e.localPosition, e.timeStamp, size, bottomInset)) {
      _pointer = e.pointer;
      _game.onSwipeStarted();
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer == _pointer) _swipe.move(e.localPosition);
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (!_swipe.tracking) return;
    final intent = _swipe.finish(e.localPosition, e.timeStamp);
    if (intent == null) {
      _game.onSwipeCanceled();
    } else {
      _game.onKickReleased(intent.contactOffset, intent.swingCurve, intent.power);
    }
  }

  void _onCancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _swipe.cancel();
    _game.onSwipeCanceled();
  }

  /// Debug klávesy (simulátor / připojená klávesnice): 1/2/3 kopy, A assist.
  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.digit1:
        _game.debugKick(Vec3.zero);
      case LogicalKeyboardKey.digit2:
        _game.debugKick(const Vec3(0, T.debugSidespin, 0));
      case LogicalKeyboardKey.digit3:
        // topspin pro let směrem -z = rotace kolem -x
        _game.debugKick(const Vec3(-T.debugTopspin, 0, 0));
      case LogicalKeyboardKey.keyA:
        setState(() => _game.assist = !_game.assist);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ── layout ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _onDown(e, size, pad.bottom),
            onPointerMove: _onMove,
            onPointerUp: _onUp,
            onPointerCancel: _onCancel,
            child: Stack(children: [
              Positioned.fill(
                child: CustomPaint(painter: ScenePainter(_game, _frame)),
              ),
              Positioned.fill(
                child: CustomPaint(
                    painter: _OverlayPainter(_game, _swipe, pad.bottom, _frame)),
              ),
              _hud(pad),
              Positioned(
                top: pad.top + 8,
                right: 12,
                child: _AssistToggle(
                  on: _game.assist,
                  onTap: () => setState(() => _game.assist = !_game.assist),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _hud(EdgeInsets pad) {
    const shadow = [Shadow(blurRadius: 6, color: Colors.black87)];
    return ValueListenableBuilder<int>(
      valueListenable: _frame,
      builder: (context, _, _) {
        final age = _game.kickTextAge;
        final kickAlpha = age < T.hudFadeDelay
            ? 1.0
            : (1 - (age - T.hudFadeDelay) / T.hudFadeTime).clamp(0.0, 1.0);
        return Stack(children: [
          Positioned(
            top: pad.top + 54,
            left: 12,
            right: 12,
            child: Opacity(
              opacity: kickAlpha,
              child: Text(
                _game.kickText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    shadows: shadow),
              ),
            ),
          ),
          Center(
            child: Text(
              _game.resultText,
              style: TextStyle(
                  color: Color(_game.resultColor),
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  shadows: shadow),
            ),
          ),
        ]);
      },
    );
  }
}

class _AssistToggle extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const _AssistToggle({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? const Color(0xCCFF8C1A) : const Color(0x66000000),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          on ? 'SLOW-MO ON' : 'SLOW-MO OFF',
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Overlay míč dole: zrcadlí rotaci reálného míče (hráč vidí faleš),
/// při tahu ukazuje kontaktní bod a dráhu prstu.
class _OverlayPainter extends CustomPainter {
  final Game game;
  final SwipeTracker swipe;
  final double bottomInset;
  _OverlayPainter(this.game, this.swipe, this.bottomInset, Listenable repaint)
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final center = SwipeTracker.overlayCenter(size, bottomInset);
    final radius = SwipeTracker.overlayRadius(size);
    final alpha = game.swipeEnabled ? 1.0 : 0.35;

    canvas.drawCircle(
        center, radius, Paint()..color = Color.fromRGBO(255, 255, 255, 0.07 * alpha));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.35 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // tělesové osy míče promítnuté na přivrácenou polokouli (+z strana)
    final b = game.ball.basis;
    for (final axis in [b.x, -b.x, b.z, -b.z]) {
      if (axis.z > 0.15) {
        canvas.drawCircle(
          center + Offset(axis.x, -axis.y) * radius * 0.8,
          radius * 0.06,
          Paint()..color = Color.fromRGBO(26, 26, 36, 0.55 * alpha),
        );
      }
    }

    if (swipe.tracking) {
      final o = swipe.contactOffset;
      canvas.drawCircle(center + Offset(o.x, -o.y) * radius, 9,
          Paint()..color = const Color(0xE6FF801A));
      if (swipe.points.length >= 2) {
        canvas.drawPoints(
          PointMode.polygon,
          swipe.points,
          Paint()
            ..color = const Color(0x9966E6FF)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
    } else if (game.swipeEnabled) {
      // nápověda: puls na overlay míči, dokud je co kopat
      final t = (game.serveTime * 3) % 1.0;
      canvas.drawCircle(
        center,
        radius * (1 + 0.15 * t),
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, 0.25 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => false;
}
