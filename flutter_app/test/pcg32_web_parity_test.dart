import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/core/serve_generator.dart';

/// Původní PCG32 na 64bitových int (jen VM); Pcg32 v polovinách se s ním musí shodovat bit po bitu.
class _Pcg32Native {
  static const _mult = 6364136223846793005;
  static const _inc = 1442695040888963407;
  int _state = 0;
  _Pcg32Native(int seed) {
    _next();
    _state += seed;
    _next();
  }
  int _next() {
    final old = _state;
    _state = old * _mult + _inc;
    final xorShifted = (((old >>> 18) ^ old) >>> 27) & 0xFFFFFFFF;
    final rot = old >>> 59;
    return ((xorShifted >>> rot) | (xorShifted << ((-rot) & 31))) & 0xFFFFFFFF;
  }

  double nextDouble() => _next() / 4294967296.0;
}

void main() {
  test('Pcg32 se shoduje s 64bitovou referencí pro řadu seedů', () {
    for (final seed in [0, 1, 2, 7, 42, 12345, 65535, 65536, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, 4294967295]) {
      final a = Pcg32(seed), b = _Pcg32Native(seed);
      for (var i = 0; i < 2000; i++) {
        expect(a.nextDouble(), b.nextDouble(), reason: 'seed $seed, draw $i');
      }
    }
  }, testOn: 'vm');
}
