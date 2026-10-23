// Port tests/gameplay_test.gd — end-to-end serve → kop v ideálním okamžiku
// → freeze-frame → gól, přes stejné API jako swipe (Game.onKickReleased).
import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/core/game.dart';
import 'package:fotball_simulator/core/tuning.dart';
import 'package:fotball_simulator/core/vec3.dart';

void main() {
  for (final seed in [12345, 1, 2, 3, 4, 5]) {
    test('perfektní volej = GÓL! (seed $seed)', () {
      final game = Game(seed: seed);
      const dt = 1 / 60; // reálný snímek 60 fps → 2 fyzikální ticky
      var guard = 0;
      while (game.state != GameState.kickWindow && guard++ < 600) {
        game.update(dt);
      }
      expect(game.state, GameState.kickWindow);

      while (game.serveTime < game.tIdeal - T.physicsDt / 2) {
        game.tick(T.physicsDt);
      }
      game.onKickReleased(const Vec2(0, -0.12), 0, 1);
      expect(game.state, GameState.flight);
      expect(game.freeze, isNotNull, reason: 'freeze-frame aktivní');

      // během freeze se svět nehýbe
      final frozenAt = game.ball.position;
      game.update(T.freezeTime / 2);
      expect(game.ball.position, frozenAt);

      guard = 0;
      while (game.state != GameState.result && guard++ < 600) {
        game.update(dt);
      }
      expect(game.freeze, isNull);
      expect(game.state, GameState.result);
      expect(game.resultText, 'GÓL!');
      expect(game.kickText, contains('PERFECT'));
    });
  }

  test('bez kopu: druhý dopad = POZDĚ, pak nový serve', () {
    final game = Game(seed: 99);
    var guard = 0;
    while (game.state != GameState.result && guard++ < 1200) {
      game.update(1 / 60);
    }
    expect(game.resultText, 'POZDĚ');
    guard = 0;
    while (game.state == GameState.result && guard++ < 600) {
      game.update(1 / 60);
    }
    expect(game.state, GameState.serve);
  });

  // B1 (ROADMAP): držený prst přes konec serve nesmí nechat slow-mo.
  test('serve vyprší při drženém prstu → slow-mo zpět na 1.0', () {
    final game = Game(seed: 7);
    var guard = 0;
    while (game.state != GameState.kickWindow && guard++ < 600) {
      game.update(1 / 60);
    }
    game.onSwipeStarted();
    expect(game.timeScale, T.assistSlowmo);
    guard = 0;
    while (game.state != GameState.result && guard++ < 1800) {
      game.update(1 / 60);
    }
    expect(game.state, GameState.result);
    expect(game.timeScale, 1.0);
    expect(game.swipeEnabled, isFalse);
  });
}
