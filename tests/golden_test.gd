extends SceneTree
## Ověření proti sdíleným golden hodnotám shared/golden.json (kontrakt
## s Flutter portem). Golden generuje Flutter strana:
##
##   cd flutter_app && UPDATE_GOLDEN=1 flutter test test/golden_test.dart
##
## Tenhle test je jen porovnává — selhání znamená, že Godot zaostal za
## Flutterem (port změny chybí) nebo se Godot změnil bez Flutteru.
## Tolerance v JSON počítají s float32 Vector3 (real_t) proti Dart double.

const T := preload("res://scripts/util/tuning.gd")
const CM := preload("res://scripts/core/contact_model.gd")
const BallScript := preload("res://scripts/core/ball_physics.gd")
const GameState := preload("res://scripts/core/game_state.gd")
const Swipe := preload("res://scripts/input/swipe_input.gd")
const KickerScript := preload("res://scripts/core/kicker.gd")

const GOLDEN_PATH := "res://shared/golden.json"
## Godot konstanty, které se od Flutteru záměrně liší (viz
## flutter_app/test/support/godot_tuning.dart)
const INTENTIONAL_DIFF := ["SERVE_SEED"]

var _failures := 0
var _tol := {}

func _initialize() -> void:
	print("=== FotballSimulator — golden_test (shared/golden.json) ===")
	var text := FileAccess.get_file_as_string(GOLDEN_PATH)
	var golden = JSON.parse_string(text)
	if typeof(golden) != TYPE_DICTIONARY:
		print("  FAIL  nejde načíst %s" % GOLDEN_PATH)
		quit(1)
		return
	_tol = golden.tolerance

	_test_tuning(golden.tuning)
	_test_contact(golden.contact)
	_test_flight(golden.flight, golden.dt)
	_test_presim(golden.presim, golden.dt)
	_test_swipe(golden.swipe)
	_test_kicker(golden.kicker, golden.dt)

	if _failures == 0:
		print("=== ALL TESTS PASSED ===")
	else:
		print("=== %d TEST(S) FAILED ===" % _failures)
	quit(0 if _failures == 0 else 1)

# ── sekce ─────────────────────────────────────────────────────

func _test_tuning(snapshot: Dictionary) -> void:
	var tuning_script: Script = T
	var consts: Dictionary = tuning_script.get_script_constant_map()
	var diffs := []
	for name in consts:
		if name in INTENTIONAL_DIFF:
			continue
		if not snapshot.has(name):
			diffs.append("%s chybí ve Flutteru / golden snapshotu" % name)
		elif not _close(_plain(consts[name]), snapshot[name], 1e-6):
			diffs.append("%s = %s vs golden %s" % [name, consts[name], snapshot[name]])
	for name in snapshot:
		if not consts.has(name):
			diffs.append("%s chybí v tuning.gd" % name)
	for d in diffs:
		print("        %s" % d)
	_expect("tuning = golden snapshot (%d rozdílů)" % diffs.size(), diffs.is_empty())

func _test_contact(cases: Array) -> void:
	for c in cases:
		var i: Dictionary = c["in"]
		var r: Dictionary = CM.compute_kick(_v2(i.offset), i.curve, i.power, i.err,
				_v3(i.ball_vel))
		_check("contact / %s" % c.name, {
			"hit": r.hit,
			"rating": String(CM.Rating.keys()[r.rating]).to_lower(),
			"vel": _plain(r.vel), "omega": _plain(r.omega),
			"timing_quality": r.timing_quality, "v_foot": r.v_foot,
		}, c.out, {
			"vel": _tol.contact, "omega": _tol.contact, "v_foot": _tol.contact,
			"timing_quality": _tol.ratio,
		})

func _test_flight(cases: Array, dt: float) -> void:
	for c in cases:
		var i: Dictionary = c["in"]
		var ball: BallPhysics = BallScript.new()
		ball.position = _v3(i.pos)
		ball.launch(_v3(i.vel), _v3(i.omega))
		var until: String = i.until
		var bounces := int(until.substr(7)) if until.begins_with("bounce:") else -1
		var apex := ball.position.y
		var ticks := 0
		while ticks < 120 * 20:
			ball._physics_process(dt)
			ticks += 1
			apex = maxf(apex, ball.position.y)
			if (ball.bounce_count >= bounces) if bounces >= 0 else not ball.flying:
				break
		_check("flight / %s" % c.name, {
			"ticks": ticks, "bounces": ball.bounce_count, "flying": ball.flying,
			"apex": apex, "pos": _plain(ball.position), "vel": _plain(ball.vel),
			"omega": _plain(ball.omega),
		}, c.out, {
			"ticks": _tol.ticks, "apex": _tol.flight, "pos": _tol.flight,
			"vel": _tol.flight, "omega": _tol.flight,
		})
		ball.free()

func _test_presim(cases: Array, dt: float) -> void:
	for k in cases.size():
		var i: Dictionary = cases[k]["in"]
		var t := GameState.presim_ideal_time(
				{"pos": _v3(i.pos), "vel": _v3(i.vel), "omega": _v3(i.omega)}, dt)
		_check("presim / #%d" % k, {"t_ideal": t}, cases[k].out,
				{"t_ideal": dt * _tol.ticks})

func _test_swipe(cases: Array) -> void:
	for c in cases:
		var i: Dictionary = c["in"]
		var pts := PackedVector2Array()
		for p in i.pts:
			pts.append(Vector2(p[0], p[1]))
		var g: Dictionary = Swipe.analyze(pts, i.duration, i.dpi)
		_check("swipe / %s" % c.name, g, c.out,
				{"power": _tol.ratio, "curve": _tol.ratio})

## Fotbalista: přehraje skript událostí, `pose` zaznamená snímek kostry.
func _test_kicker(cases: Array, dt: float) -> void:
	for c in cases:
		var i: Dictionary = c["in"]
		var k: Kicker = KickerScript.new(
				Kicker.Foot.RIGHT if i.foot == "right" else Kicker.Foot.LEFT)
		var poses := []
		for op in i.script:
			match op[0]:
				"serve":
					k.on_serve(_v3(op[1]))
				"tick":
					for n in int(op[1]):
						k.update(dt)
				"windup":
					k.windup()
				"cancel":
					k.cancel_windup()
				"strike":
					k.strike(_v3(op[1]), _v3(op[2]), _v3(op[3]), op[4])
				"pose":
					var snap := {"phase": String(Kicker.Phase.keys()[k.phase]).to_lower()}
					var p: Dictionary = k.pose()
					for joint in p:
						snap[joint] = _plain(p[joint])
					poses.append(snap)
		_check("kicker / %s" % c.name, {"poses": poses}, c.out,
				{"poses": _tol.contact})

# ── pomocníci ─────────────────────────────────────────────────

## Porovná všechny klíče golden výstupu; tolerance dle klíče (jinak přesně).
## Při neshodě vypíše první rozdílnou cestu (např. poses[3].kneeR[1]).
func _check(label: String, got: Dictionary, want: Dictionary, tol: Dictionary) -> void:
	var bad := []
	for key in want:
		var diff := _diff(got.get(key), want[key], tol.get(key, 0.0), key)
		if diff != "":
			bad.append(diff)
	_expect(label + ("" if bad.is_empty() else "  [%s]" % ", ".join(bad)),
			bad.is_empty())

## "" = shoda v toleranci, jinak popis prvního rozdílu.
func _diff(got: Variant, want: Variant, tol: float, path: String) -> String:
	if want is Dictionary:
		if not got is Dictionary:
			return "%s: chybí" % path
		for key in want:
			var d := _diff(got.get(key), want[key], tol, "%s.%s" % [path, key])
			if d != "":
				return d
		if got.size() != want.size():
			return "%s: jiné klíče" % path
		return ""
	if want is Array:
		if not got is Array or got.size() != want.size():
			return "%s: jiná délka" % path
		for k in want.size():
			var d := _diff(got[k], want[k], tol, "%s[%d]" % [path, k])
			if d != "":
				return d
		return ""
	if want is float or want is int:
		if (got is float or got is int) and absf(float(got) - float(want)) <= tol:
			return ""
		return "%s: %s ≠ %s" % [path, got, want]
	return "" if got == want else "%s: %s ≠ %s" % [path, got, want]

func _close(got: Variant, want: Variant, tol: float) -> bool:
	return _diff(got, want, tol, "") == ""

## Vector3/Vector2 → [x, y, z] jako v JSON.
func _plain(v: Variant) -> Variant:
	if v is Vector3:
		return [v.x, v.y, v.z]
	if v is Vector2:
		return [v.x, v.y]
	return v

func _v3(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])

func _v2(a: Array) -> Vector2:
	return Vector2(a[0], a[1])

func _expect(label: String, cond: bool) -> void:
	if cond:
		print("  PASS  %s" % label)
	else:
		print("  FAIL  %s" % label)
		_failures += 1
