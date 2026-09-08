extends SceneTree
## Headless fyzikální testy Fáze 0 (VOLLEY_PLAN.md §8). Bez GUT — framework
## přijde s Fází 1 (contact_model); tady stačí čistý SceneTree skript:
##
##   godot --headless --path . --script res://tests/physics_test.gd
##
## Referenční hodnoty spočítané nezávislou implementací stejného modelu
## (Python, float64, semi-implicit Euler 120 Hz). Pozn.: plán §7 uvádí
## "25 m/s @ 35° → ~24 m", ale s konstantami z §3 (CD=0.25) vychází
## ~38.9 m — reference níže odpovídá konstantám, ne odhadu z plánu.

const T := preload("res://scripts/util/tuning.gd")
const BallScript := preload("res://scripts/core/ball_physics.gd")
const ServeGen := preload("res://scripts/core/serve_generator.gd")

const DT := 1.0 / 120.0
const MAX_TICKS := 120 * 12

# Python reference (viz hlavička)
const REF_RANGE_NO_SPIN := 38.921
const REF_APEX_NO_SPIN := 8.256
const REF_X_SIDESPIN := -9.693
const REF_RANGE_TOPSPIN := 32.982

var _failures := 0

func _initialize() -> void:
	print("=== FotballSimulator — physics_test (Fáze 0) ===")
	_test_range_no_spin()
	_test_sidespin_curves()
	_test_topspin_drops_short()
	_test_bounce_restitution()
	_test_serve_deterministic()
	_test_serve_lands_in_kick_zone()

	if _failures == 0:
		print("=== ALL TESTS PASSED ===")
	else:
		print("=== %d TEST(S) FAILED ===" % _failures)
	quit(0 if _failures == 0 else 1)

# ── testy ─────────────────────────────────────────────────────

func _test_range_no_spin() -> void:
	var r := _fly(_kick_vel(), Vector3.ZERO)
	_expect_near("dolet bez spinu", r.range, REF_RANGE_NO_SPIN, 0.05)
	_expect_near("vrchol bez spinu", r.apex, REF_APEX_NO_SPIN, 0.05)
	_expect("bez spinu neuhýbá do strany (|x|=%.3f)" % absf(r.x), absf(r.x) < 0.05)

func _test_sidespin_curves() -> void:
	var r := _fly(_kick_vel(), Vector3(0, 50, 0))
	_expect_near("faleš: boční výchylka", r.x, REF_X_SIDESPIN, 0.05)

func _test_topspin_drops_short() -> void:
	var r := _fly(_kick_vel(), Vector3(-40, 0, 0))
	_expect_near("topspin: dolet", r.range, REF_RANGE_TOPSPIN, 0.05)
	_expect("topspin nedoletí (%.1f < %.1f m)" % [r.range, REF_RANGE_NO_SPIN * 0.9],
			r.range < REF_RANGE_NO_SPIN * 0.9)

func _test_bounce_restitution() -> void:
	var ball: BallPhysics = BallScript.new()
	var impact := [0.0]
	ball.bounced.connect(func(_pos: Vector3, speed: float) -> void: impact[0] = speed)
	ball.position = Vector3(0, 2.0, 0)
	ball.launch(Vector3.ZERO, Vector3.ZERO)
	var ticks := 0
	while ball.bounce_count < 1 and ticks < MAX_TICKS:
		ball._physics_process(DT)
		ticks += 1
	var ratio: float = ball.vel.y / impact[0]
	_expect_near("restituce odskoku", ratio, T.RESTITUTION, 0.001)
	ball.free()

func _test_serve_deterministic() -> void:
	var gen_a: ServeGenerator = ServeGen.new(42)
	var gen_b: ServeGenerator = ServeGen.new(42)
	var same := true
	var first_a: Dictionary = {}
	for i in 5:
		var a: Dictionary = gen_a.next_serve()
		var b: Dictionary = gen_b.next_serve()
		if i == 0:
			first_a = a
		if a.pos != b.pos or a.vel != b.vel or a.omega != b.omega:
			same = false
	_expect("serve_generator: stejný seed ⇒ stejná sekvence", same)

	# celá trajektorie musí být bit-po-bitu shodná
	var ball_a: BallPhysics = BallScript.new()
	var ball_b: BallPhysics = BallScript.new()
	ball_a.position = first_a.pos
	ball_b.position = first_a.pos
	ball_a.launch(first_a.vel, first_a.omega)
	ball_b.launch(first_a.vel, first_a.omega)
	var identical := true
	for i in 240:
		ball_a._physics_process(DT)
		ball_b._physics_process(DT)
		if ball_a.position != ball_b.position:
			identical = false
			break
	_expect("trajektorie deterministická (240 ticků)", identical)
	ball_a.free()
	ball_b.free()

func _test_serve_lands_in_kick_zone() -> void:
	var gen: ServeGenerator = ServeGen.new(7)
	var ok := true
	for i in 10:
		var s: Dictionary = gen.next_serve()
		var ball: BallPhysics = BallScript.new()
		ball.position = s.pos
		ball.launch(s.vel, s.omega)
		var ticks := 0
		while ball.bounce_count < 1 and ticks < MAX_TICKS:
			ball._physics_process(DT)
			ticks += 1
		# první dopad musí být před hráčem v kop-zóně
		if ball.position.z < -3.2 or ball.position.z > -0.5 or absf(ball.position.x) > 1.0:
			print("  serve %d dopadl mimo zónu: %v" % [i, ball.position])
			ok = false
		ball.free()
	_expect("serve dopadá do kop-zóny (10 seedů)", ok)

# ── pomocníci ─────────────────────────────────────────────────

## Debug kop z plánu: 25 m/s @ 35° směrem -z.
func _kick_vel() -> Vector3:
	var angle := deg_to_rad(35.0)
	return Vector3(0, 25.0 * sin(angle), -25.0 * cos(angle))

## Odsimuluje let do prvního dopadu, vrátí {range, x, apex}.
func _fly(vel: Vector3, spin: Vector3) -> Dictionary:
	var ball: BallPhysics = BallScript.new()
	ball.position = Vector3(0, T.BALL_RADIUS, 0)
	ball.launch(vel, spin)
	var apex := 0.0
	var ticks := 0
	while ball.bounce_count < 1 and ticks < MAX_TICKS:
		ball._physics_process(DT)
		apex = maxf(apex, ball.position.y)
		ticks += 1
	var result := {"range": -ball.position.z, "x": ball.position.x, "apex": apex}
	ball.free()
	return result

func _expect(label: String, cond: bool) -> void:
	if cond:
		print("  PASS  %s" % label)
	else:
		print("  FAIL  %s" % label)
		_failures += 1

func _expect_near(label: String, value: float, ref: float, rel_tol: float) -> void:
	var err: float = absf(value - ref) / maxf(absf(ref), 0.001)
	if err <= rel_tol:
		print("  PASS  %s: %.3f (ref %.3f, odchylka %.2f %%)" % [label, value, ref, err * 100.0])
	else:
		print("  FAIL  %s: %.3f (ref %.3f, odchylka %.2f %% > %.0f %%)"
				% [label, value, ref, err * 100.0, rel_tol * 100.0])
		_failures += 1
