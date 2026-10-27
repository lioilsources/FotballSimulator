// Hlídá, že `lib/core/tuning.dart` drží krok se `scripts/util/tuning.gd`.
// Parsuje Godot zdroják přímo (CI Godot nemá), takže drift chytí běžný
// `flutter test`. Mapa jmen je v support/godot_tuning.dart.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/core/tuning.dart';
import 'package:fotball_simulator/core/vec3.dart';

import 'support/godot_tuning.dart';

final _gdConst = RegExp(r'^const\s+(\w+)\s*:?=\s*(.+?)\s*(?:#.*)?$');
final _dartConst = RegExp(r'^\s*static const (\w+)\s*=');
final _vector3 = RegExp(r'^Vector3\(\s*([^,]+),\s*([^,]+),\s*([^)]+)\)$');

/// Hodnota konstanty z tuning.gd: číslo, bool, Vector3 nebo součin
/// čísel / PI / dřívějších konstant (BALL_AREA). Jinak null.
Object? _evalGd(String expr, Map<String, Object> known) {
  if (expr == 'true') return true;
  if (expr == 'false') return false;
  final v = _vector3.firstMatch(expr);
  if (v != null) {
    return Vec3(double.parse(v[1]!), double.parse(v[2]!), double.parse(v[3]!));
  }
  final n = num.tryParse(expr);
  if (n != null) return n;
  var product = 1.0;
  for (final f in expr.split('*').map((s) => s.trim())) {
    final k = f == 'PI' ? math.pi : (num.tryParse(f) ?? known[f]);
    if (k is! num) return null;
    product *= k;
  }
  return product;
}

void main() {
  final gdSource =
      File('$repoRoot/scripts/util/tuning.gd').readAsLinesSync();
  final gd = <String, Object>{};
  final unparsed = <String>[];
  for (final line in gdSource) {
    final m = _gdConst.firstMatch(line);
    if (m == null) continue;
    final value = _evalGd(m[2]!, gd);
    if (value == null) {
      unparsed.add('${m[1]} = ${m[2]}');
    } else {
      gd[m[1]!] = value;
    }
  }
  final dartNames = {
    for (final line in File('lib/core/tuning.dart').readAsLinesSync())
      if (_dartConst.firstMatch(line) case final m?) m[1]!,
  };

  test('tuning.gd jde celé naparsovat', () {
    expect(gd, isNotEmpty);
    expect(unparsed, isEmpty,
        reason: 'neumím vyhodnotit — rozšiř _evalGd nebo zjednoduš výraz');
  });

  test('každá Godot konstanta má Dart protějšek', () {
    final missing = gd.keys
        .where((k) => !godotTuning.containsKey(k) && !intentionalDiff.containsKey(k))
        .toList();
    expect(missing, isEmpty,
        reason: 'doplň do tuning.dart a do support/godot_tuning.dart');
    final stale = godotTuning.keys.where((k) => !gd.containsKey(k)).toList();
    expect(stale, isEmpty, reason: 'konstanta zmizela z tuning.gd');
  });

  test('každá Dart konstanta má Godot protějšek (nebo je flutterOnly)', () {
    final mapped = {
      ...godotTuning.values.map((e) => e.$1),
      ...intentionalDiff.values,
      ...flutterOnly,
    };
    expect(dartNames.where((n) => !mapped.contains(n)).toList(), isEmpty,
        reason: 'doplň do tuning.gd, nebo do flutterOnly s důvodem');
    expect(mapped.where((n) => !dartNames.contains(n)).toList(), isEmpty,
        reason: 'mapa odkazuje na neexistující Dart jméno');
  });

  test('hodnoty se shodují', () {
    final diffs = <String>[];
    godotTuning.forEach((name, entry) {
      final (dartName, dv) = entry;
      final gv = gd[name];
      final same = switch ((gv, dv)) {
        (Vec3 a, Vec3 b) =>
          (a - b).length < 1e-12,
        (num a, num b) => (a - b).abs() <= 1e-12 * math.max(1, a.abs()),
        (bool a, bool b) => a == b,
        _ => false,
      };
      if (!same) diffs.add('$name = $gv  vs  T.$dartName = $dv');
    });
    expect(diffs, isEmpty);
  });

  test('physics tick = project.godot', () {
    final project = File('$repoRoot/project.godot').readAsStringSync();
    final m = RegExp(r'physics_ticks_per_second=(\d+)').firstMatch(project);
    expect(int.parse(m![1]!), T.physicsHz);
  });
}
