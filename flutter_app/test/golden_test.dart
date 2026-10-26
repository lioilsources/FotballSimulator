// Sdílené golden hodnoty `shared/golden.json` — kontrakt mezi Flutter a
// Godot verzí. Flutter je vede (hlavní vývoj), Godot je ověřuje
// (`tests/golden_test.gd`). Po záměrné změně fyziky / tuningu:
//
//   UPDATE_GOLDEN=1 flutter test test/golden_test.dart
//
// a pak portovat změnu do Godotu, dokud nebude zelený i tests/golden_test.gd.
// Vstupy případů žijí tady (_cases); porovnání jede ze vstupů uložených
// v JSON, takže obě strany počítají přesně totéž.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/core/ball_physics.dart';
import 'package:fotball_simulator/core/contact_model.dart';
import 'package:fotball_simulator/core/game.dart';
import 'package:fotball_simulator/core/serve_generator.dart';
import 'package:fotball_simulator/core/tuning.dart';
import 'package:fotball_simulator/core/vec3.dart';
import 'package:fotball_simulator/ui/swipe_input.dart';

import 'support/godot_tuning.dart';

final _file = File('$repoRoot/shared/golden.json');

// Godot Vector3 je float32 (real_t), Dart double — tolerance proto
// odpovídají kumulaci float32 chyby, ne bitové shodě.
const _tolerance = {
  'contact': 1e-4, // m/s, rad/s (výstupy řádu 10–70)
  'flight': 5e-3, // m, m/s po stovkách ticků
  'ratio': 1e-5, // timing_quality, power, curve
  'ticks': 1, // přechod odskok/kutálení se může posunout o tick
};

List<double> _v(Vec3 v) => [v.x, v.y, v.z];
Vec3 _vec(List<dynamic> a) => Vec3(
    (a[0] as num).toDouble(), (a[1] as num).toDouble(), (a[2] as num).toDouble());

// ── vstupy ────────────────────────────────────────────────────

Map<String, Object> _contactIn(double ox, double oy,
        {double curve = 0, double power = 1, double err = 0,
        Vec3 ballVel = Vec3.zero}) =>
    {
      'offset': [ox, oy], 'curve': curve, 'power': power, 'err': err,
      'ball_vel': _v(ballVel),
    };

final _contactCases = {
  'střed': _contactIn(0, 0),
  'nízký volej': _contactIn(0, -0.12),
  'offset vpravo': _contactIn(0.5, 0),
  'offset vlevo': _contactIn(-0.5, 0),
  'pod míč': _contactIn(0, -0.5),
  'extrémní offset (limit 0.95)': _contactIn(0.9, -0.6),
  'oblouk doprava': _contactIn(0, 0, curve: 1),
  'oblouk doleva + offset': _contactIn(-0.3, -0.2, curve: -0.6),
  'GOOD 50 ms': _contactIn(0, -0.12, err: 0.05),
  'LATE 90 ms': _contactIn(0, -0.3, err: 0.09),
  'EARLY -100 ms': _contactIn(0, -0.3, err: -0.1),
  'MISS 200 ms': _contactIn(0, -0.12, err: 0.2, ballVel: const Vec3(0, -2, 4)),
  'poloviční síla': _contactIn(0, 0, power: 0.5),
  'příchozí míč, silný kop': _contactIn(0, -0.12, ballVel: const Vec3(0, -2, 4)),
  'příchozí míč, pozdní tečování':
      _contactIn(0, -0.12, err: 0.09, ballVel: const Vec3(0.6, -2, 4)),
  'míč utíká nártu': _contactIn(0, 0, power: 0.1, ballVel: const Vec3(0, 0, -10)),
};

Map<String, Object> _flightIn(Vec3 pos, Vec3 vel, Vec3 omega, String until) =>
    {'pos': _v(pos), 'vel': _v(vel), 'omega': _v(omega), 'until': until};

final _debugVel = Vec3(0, 25 * 0.573576436351046, -25 * 0.819152044288992); // 35°
const _ground = Vec3(0, T.ballRadius, 0);

final _flightCases = {
  'debug kop bez spinu → 1. dopad': _flightIn(_ground, _debugVel, Vec3.zero, 'bounce:1'),
  'faleš 50 rad/s → 1. dopad':
      _flightIn(_ground, _debugVel, const Vec3(0, 50, 0), 'bounce:1'),
  'topspin 40 → 1. dopad': _flightIn(_ground, _debugVel, const Vec3(-40, 0, 0), 'bounce:1'),
  'backspin + faleš → 3. dopad':
      _flightIn(_ground, _debugVel, const Vec3(25, -20, 0), 'bounce:3'),
  'nízký topspin → kutálení → stop': _flightIn(
      const Vec3(0, 0.55, -1.8), const Vec3(0, 2, -14), const Vec3(-30, 0, 0), 'stop'),
  'pád z 2 m → stop': _flightIn(const Vec3(0, 2, 0), Vec3.zero, Vec3.zero, 'stop'),
};

List<Map<String, Object>> _presimInputs() {
  Map<String, Object> s(Serve v) =>
      {'pos': _v(v.pos), 'vel': _v(v.vel), 'omega': _v(v.omega)};
  return [
    for (final seed in [1, 7, 42]) s(ServeGenerator(seed).nextServe()),
    // slabý odskok nedosáhne IDEAL_KICK_HEIGHT → fallback na vrchol
    s(const Serve(Vec3(0, 0.4, -2.5), Vec3(0, -0.5, 1.0), Vec3.zero)),
  ];
}

Map<String, Object> _swipeIn(List<Offset> pts, double duration, double dpi) => {
      'pts': [for (final p in pts) [p.dx, p.dy]],
      'duration': duration, 'dpi': dpi,
    };

List<Offset> _line(Offset a, Offset b, int n) =>
    [for (var i = 0; i <= n; i++) Offset.lerp(a, b, i / n)!];

/// Oblouk: tětiva a→b, vyboulení `bulge` px kolmo (+ = doprava vůči tahu).
List<Offset> _arc(Offset a, Offset b, double bulge, int n) {
  final d = b - a;
  final normal = Offset(-d.dy, d.dx) / d.distance;
  return [
    for (var i = 0; i <= n; i++)
      Offset.lerp(a, b, i / n)! + normal * (bulge * math.sin(math.pi * i / n))
  ];
}

final _swipeCases = {
  'rovný tah 160 DPI': _swipeIn(_line(const Offset(100, 500), const Offset(100, 200), 10), 0.5, 160),
  'rovný tah 480 DPI': _swipeIn(_line(const Offset(300, 1500), const Offset(300, 600), 10), 0.5, 480),
  'saturace síly': _swipeIn(_line(const Offset(100, 500), const Offset(100, 200), 10), 0.1, 160),
  'oblouk doprava': _swipeIn(_arc(const Offset(100, 500), const Offset(100, 200), 60, 12), 0.3, 160),
  'šikmý oblouk doleva': _swipeIn(_arc(const Offset(50, 500), const Offset(200, 220), -45, 12), 0.25, 160),
  'krátký = zrušeno': _swipeIn(_line(Offset.zero, const Offset(0, -15), 4), 0.3, 160),
};

// ── výpočty (stejná logika jako tests/golden_test.gd) ─────────

Map<String, Object> _runContact(Map<String, dynamic> i) {
  final o = i['offset'] as List;
  final r = ContactModel.computeKick(
    Vec2((o[0] as num).toDouble(), (o[1] as num).toDouble()),
    (i['curve'] as num).toDouble(),
    (i['power'] as num).toDouble(),
    (i['err'] as num).toDouble(),
    _vec(i['ball_vel'] as List),
  );
  return {
    'hit': r.hit, 'rating': r.rating.name, 'vel': _v(r.vel),
    'omega': _v(r.omega), 'timing_quality': r.timingQuality, 'v_foot': r.vFoot,
  };
}

Map<String, Object> _runFlight(Map<String, dynamic> i) {
  final ball = BallPhysics()..position = _vec(i['pos'] as List);
  ball.launch(_vec(i['vel'] as List), _vec(i['omega'] as List));
  final until = i['until'] as String;
  final bounces = until.startsWith('bounce:') ? int.parse(until.substring(7)) : -1;
  var apex = ball.position.y;
  var ticks = 0;
  while (ticks < 120 * 20) {
    ball.step(T.physicsDt);
    ticks++;
    if (ball.position.y > apex) apex = ball.position.y;
    if (bounces >= 0 ? ball.bounceCount >= bounces : !ball.flying) break;
  }
  return {
    'ticks': ticks, 'bounces': ball.bounceCount, 'flying': ball.flying,
    'apex': apex, 'pos': _v(ball.position), 'vel': _v(ball.vel),
    'omega': _v(ball.omega),
  };
}

Map<String, Object> _runPresim(Map<String, dynamic> i) => {
      't_ideal': Game.presimIdealTime(Serve(
          _vec(i['pos'] as List), _vec(i['vel'] as List), _vec(i['omega'] as List))),
    };

Map<String, Object> _runSwipe(Map<String, dynamic> i) {
  final g = SwipeTracker.analyze(
    [for (final p in i['pts'] as List) Offset((p[0] as num).toDouble(), (p[1] as num).toDouble())],
    (i['duration'] as num).toDouble(),
    (i['dpi'] as num).toDouble(),
  );
  return {'ok': g.ok, 'power': g.power, 'curve': g.curve};
}

// ── generování / porovnání ────────────────────────────────────

List<Map<String, Object>> _section(Map<String, Map<String, Object>> cases,
        Map<String, Object> Function(Map<String, dynamic>) run) =>
    [
      for (final MapEntry(:key, :value) in cases.entries)
        {'name': key, 'in': value, 'out': run(value)}
    ];

void _expectClose(String where, Object? got, Object? want, double tol) {
  if (want is Map) {
    final g = got as Map;
    expect(g.keys.toSet(), want.keys.toSet(), reason: where);
    for (final key in want.keys) {
      _expectClose('$where.$key', g[key], want[key], tol);
    }
  } else if (want is num) {
    expect((got as num) - want, inInclusiveRange(-tol, tol), reason: where);
  } else if (want is List) {
    final g = got as List;
    expect(g.length, want.length, reason: where);
    for (var k = 0; k < want.length; k++) {
      _expectClose('$where[$k]', g[k], want[k], tol);
    }
  } else {
    expect(got, want, reason: where);
  }
}

void _compare(String section, List<dynamic> cases,
    Map<String, Object> Function(Map<String, dynamic>) run,
    Map<String, double> tolByKey) {
  for (final c in cases) {
    final got = run(c['in'] as Map<String, dynamic>);
    (c['out'] as Map<String, dynamic>).forEach((key, want) {
      _expectClose('$section / ${c['name']} / $key', got[key], want,
          tolByKey[key] ?? 0);
    });
  }
}

void main() {
  if (Platform.environment['UPDATE_GOLDEN'] == '1') {
    test('regenerovat shared/golden.json', () {
      final golden = {
        '_comment': 'GENEROVÁNO: UPDATE_GOLDEN=1 flutter test test/golden_test.dart '
            '(v flutter_app/). Needitovat ručně. Ověřuje tests/golden_test.gd.',
        'tolerance': _tolerance,
        'dt': T.physicsDt,
        'tuning': tuningSnapshot(),
        'contact': _section(_contactCases, _runContact),
        'flight': _section(_flightCases, _runFlight),
        'presim': [
          for (final i in _presimInputs()) {'in': i, 'out': _runPresim(i)}
        ],
        'swipe': _section(_swipeCases, _runSwipe),
      };
      _file.parent.createSync(recursive: true);
      _file.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(golden)}\n');
    });
    return;
  }

  final golden = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
  final tol = (golden['tolerance'] as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, (v as num).toDouble()));

  test('tuning snapshot = aktuální tuning (jinak regenerovat golden)', () {
    _expectClose('tuning', golden['tuning'], tuningSnapshot(), 1e-12);
  });

  test('contact model', () {
    _compare('contact', golden['contact'] as List, _runContact, {
      'vel': tol['contact']!, 'omega': tol['contact']!,
      'v_foot': tol['contact']!, 'timing_quality': tol['ratio']!,
    });
  });

  test('let míče', () {
    _compare('flight', golden['flight'] as List, _runFlight, {
      'ticks': tol['ticks']!, 'apex': tol['flight']!, 'pos': tol['flight']!,
      'vel': tol['flight']!, 'omega': tol['flight']!,
    });
  });

  test('pre-simulace ideálního okamžiku', () {
    _compare('presim', golden['presim'] as List, _runPresim,
        {'t_ideal': (golden['dt'] as num).toDouble() * tol['ticks']!});
  });

  test('swipe analyze', () {
    _compare('swipe', golden['swipe'] as List, _runSwipe,
        {'power': tol['ratio']!, 'curve': tol['ratio']!});
  });
}
