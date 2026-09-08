extends SceneTree
## Tabulkové testy contact modelu (VOLLEY_PLAN.md §8, Fáze 1):
##
##   godot --headless --path . --script res://tests/contact_test.gd
##
## Lokální rámec: -z = na bránu, +x doprava, +y nahoru. Fyzikální znaménka:
## topspin pro let -z = omega.x < 0, sidespin omega.y > 0 ⇒ Magnus +x.

const T := preload("res://scripts/util/tuning.gd")
const CM := preload("res://scripts/core/contact_model.gd")
const BallScript := preload("res://scripts/core/ball_physics.gd")

const DT := 1.0 / 120.0
var _failures := 0

func _initialize() -> void:
	print("=== FotballSimulator — contact_test (Fáze 1) ===")
	_test_center_hit()
	_test_side_hits()
	_test_loft()
	_test_curve_swipe()
	_test_timing_ratings()
	_test_late_shift_mechanics()
	_test_power_scaling()
	_test_perfect_volley_scores()

	if _failures == 0:
		print("=== ALL TESTS PASSED ===")
	else:
		print("=== %d TEST(S) FAILED ===" % _failures)
	quit(0 if _failures == 0 else 1)

# ── tabulkové případy ─────────────────────────────────────────

func _test_center_hit() -> void:
	var r: Dictionary = CM.compute_kick(Vector2.ZERO, 0.0, 1.0, 0.0)
	_expect("střed: zásah", r.hit)
	_expect("střed: rating PERFECT", r.rating == CM.Rating.PERFECT)
	_expect("střed: letí na bránu (vz=%.1f)" % r.vel.z, r.vel.z < -25.0)
	_expect("střed: neuhýbá (|vx|=%.3f)" % absf(r.vel.x), absf(r.vel.x) < 0.01)
	_expect("střed: mírný topspin ze zdvihu švihu (ωx=%.1f)" % r.omega.x,
			r.omega.x < -5.0)
	_expect("střed: bez sidespinu (|ωy|=%.3f)" % absf(r.omega.y),
			absf(r.omega.y) < 0.01)

func _test_side_hits() -> void:
	# zásah VPRAVO na míči → míč letí doleva, spin ho Magnusem vrací doprava
	var right: Dictionary = CM.compute_kick(Vector2(0.5, 0.0), 0.0, 1.0, 0.0)
	_expect("offset vpravo: letí doleva (vx=%.1f)" % right.vel.x, right.vel.x < -3.0)
	_expect("offset vpravo: spin doprava (ωy=%.1f)" % right.omega.y, right.omega.y > 10.0)

	var left: Dictionary = CM.compute_kick(Vector2(-0.5, 0.0), 0.0, 1.0, 0.0)
	_expect("offset vlevo: letí doprava (vx=%.1f)" % left.vel.x, left.vel.x > 3.0)
	_expect("offset vlevo: spin doleva (ωy=%.1f)" % left.omega.y, left.omega.y < -10.0)

	_expect("zrcadlová symetrie L/R",
			absf(right.vel.x + left.vel.x) < 0.001
			and absf(right.omega.y + left.omega.y) < 0.001)

func _test_loft() -> void:
	var center: Dictionary = CM.compute_kick(Vector2.ZERO, 0.0, 1.0, 0.0)
	var under: Dictionary = CM.compute_kick(Vector2(0, -0.5), 0.0, 1.0, 0.0)
	_expect("pod míč: vyšší elevace", under.vel.y > center.vel.y + 5.0)
	_expect("pod míč: backspin (ωx=%.1f)" % under.omega.x, under.omega.x > 3.0)

func _test_curve_swipe() -> void:
	var r: Dictionary = CM.compute_kick(Vector2.ZERO, 1.0, 1.0, 0.0)
	_expect("swipe doprava: faleš doprava (ωy=%.1f)" % r.omega.y, r.omega.y < -20.0)
	var l: Dictionary = CM.compute_kick(Vector2.ZERO, -1.0, 1.0, 0.0)
	_expect("swipe doleva: faleš doleva (ωy=%.1f)" % l.omega.y, l.omega.y > 20.0)

func _test_timing_ratings() -> void:
	_expect("err 0 ⇒ PERFECT",
			CM.compute_kick(Vector2.ZERO, 0, 1, 0.0).rating == CM.Rating.PERFECT)
	_expect("err 50 ms ⇒ GOOD",
			CM.compute_kick(Vector2.ZERO, 0, 1, 0.05).rating == CM.Rating.GOOD)
	_expect("err +100 ms ⇒ LATE",
			CM.compute_kick(Vector2.ZERO, 0, 1, 0.10).rating == CM.Rating.LATE)
	_expect("err -100 ms ⇒ EARLY",
			CM.compute_kick(Vector2.ZERO, 0, 1, -0.10).rating == CM.Rating.EARLY)
	var miss: Dictionary = CM.compute_kick(Vector2.ZERO, 0, 1, 0.2)
	_expect("err 200 ms ⇒ MISS bez impulsu",
			miss.rating == CM.Rating.MISS and not miss.hit and miss.vel == Vector3.ZERO)

## §3.4/6 — "pozdě = nedoletí" musí vzniknout mechanicky, ne penalizací.
func _test_late_shift_mechanics() -> void:
	var aim := Vector2(0, -0.3)
	var on_time: Dictionary = CM.compute_kick(aim, 0.0, 1.0, 0.0)
	var late: Dictionary = CM.compute_kick(aim, 0.0, 1.0, 0.09)

	var elev_on := atan2(on_time.vel.y, -on_time.vel.z)
	var elev_late := atan2(late.vel.y, -late.vel.z)
	_expect("pozdě: nižší dráha (%.0f° < %.0f°)"
			% [rad_to_deg(elev_late), rad_to_deg(elev_on)],
			elev_late < elev_on - 0.05)
	# spin normalizovaný rychlostí nártu — geometrie kontaktu se musí posunout
	# k topspinu bez ohledu na to, že pozdní zásah zároveň ztrácí energii
	var spin_rate_on: float = on_time.omega.x / on_time.v_foot
	var spin_rate_late: float = late.omega.x / late.v_foot
	_expect("pozdě: víc topspinu na jednotku švihu (%.2f < %.2f)"
			% [spin_rate_late, spin_rate_on],
			spin_rate_late < spin_rate_on - 0.1)
	_expect("pozdě: slabší kontakt", late.vel.length() < on_time.vel.length() * 0.5)

func _test_power_scaling() -> void:
	var half: Dictionary = CM.compute_kick(Vector2.ZERO, 0.0, 0.5, 0.0)
	var full: Dictionary = CM.compute_kick(Vector2.ZERO, 0.0, 1.0, 0.0)
	_expect("síla škáluje rychlost (%.1f < %.1f)"
			% [half.vel.length(), full.vel.length()],
			half.vel.length() < full.vel.length() * 0.6)

## Integrace: perfektní nízký volej z kop-zóny musí projít bránou.
func _test_perfect_volley_scores() -> void:
	var kick: Dictionary = CM.compute_kick(Vector2(0, -0.12), 0.0, 1.0, 0.0)
	var ball: BallPhysics = BallScript.new()
	# míč ve výšce ideálního kontaktu, 1.8 m před hráčem; rámec = svět (míří -z)
	ball.position = Vector3(0, T.IDEAL_KICK_HEIGHT, -1.8)
	ball.launch(kick.vel, kick.omega)
	var crossed := false
	var cross_pos := Vector3.ZERO
	var ticks := 0
	while ball.flying and ticks < 120 * 5:
		var prev := ball.position
		ball._physics_process(DT)
		ticks += 1
		if prev.z > -T.GOAL_DISTANCE and ball.position.z <= -T.GOAL_DISTANCE:
			crossed = true
			cross_pos = ball.position
			break
	_expect("volej doletí k bráně", crossed)
	if crossed:
		_expect("gól: uvnitř rámu (x=%.2f, y=%.2f) · %.0f km/h"
				% [cross_pos.x, cross_pos.y, ball.vel.length() * 3.6],
				absf(cross_pos.x) < T.GOAL_HALF_WIDTH
				and cross_pos.y > 0.0 and cross_pos.y < T.GOAL_HEIGHT)
	ball.free()

# ── pomocníci ─────────────────────────────────────────────────

func _expect(label: String, cond: bool) -> void:
	if cond:
		print("  PASS  %s" % label)
	else:
		print("  FAIL  %s" % label)
		_failures += 1
