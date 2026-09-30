extends SceneTree
## Testy geometrie swipe gesta (ROADMAP T2 / B4): čisté statické funkce
## swipe_input.gd bez Control uzlu a bez vstupních událostí.
##
##   godot --headless --path . --script res://tests/swipe_test.gd
##
## Obrazovkové souřadnice: y roste dolů. Tah "nahoru" = klesající y.

const T := preload("res://scripts/util/tuning.gd")
const Swipe := preload("res://scripts/input/swipe_input.gd")

var _failures := 0

func _initialize() -> void:
	print("=== FotballSimulator — swipe_test (B4) ===")
	_test_power_dpi()
	_test_curve_sign()
	_test_cancel_conditions()
	_test_point_cap()

	if _failures == 0:
		print("=== ALL TESTS PASSED ===")
	else:
		print("=== %d TEST(S) FAILED ===" % _failures)
	quit(0 if _failures == 0 else 1)

# ── testy ─────────────────────────────────────────────────────

func _test_power_dpi() -> void:
	# 300 px nahoru za 0.5 s při 160 DPI = 3.75 in/s = 0.3125 plné síly
	var pts := _line(Vector2(100, 500), Vector2(100, 200), 10)
	var g: Dictionary = Swipe.analyze(pts, 0.5, 160.0)
	_expect("rovný tah: ok", g.ok)
	_expect("síla z rychlosti (%.3f)" % g.power,
			absf(g.power - 3.75 / T.SWIPE_POWER_FULL_INS) < 0.01)
	_expect("rovný tah: bez zakřivení (%.3f)" % g.curve, absf(g.curve) < 0.01)
	# stejný fyzický pohyb na 3× DPI = 3× víc px ⇒ stejná síla
	var hi := _line(Vector2(300, 1500), Vector2(300, 600), 10)
	var gh: Dictionary = Swipe.analyze(hi, 0.5, 480.0)
	_expect("DPI normalizace (%.3f vs %.3f)" % [gh.power, g.power],
			absf(gh.power - g.power) < 0.001)
	# rychlý švih saturuje na 1.0
	_expect("plná síla saturuje", Swipe.analyze(pts, 0.1, 160.0).power == 1.0)

func _test_curve_sign() -> void:
	# tah nahoru s vyboulením doprava (+x) ⇒ curve > 0
	var right := _arc(Vector2(100, 500), Vector2(100, 200), 60.0)
	var gr: Dictionary = Swipe.analyze(right, 0.3, 160.0)
	_expect("oblouk doprava ⇒ curve > 0 (%.2f)" % gr.curve, gr.curve > 0.2)
	var left := _arc(Vector2(100, 500), Vector2(100, 200), -60.0)
	var gl: Dictionary = Swipe.analyze(left, 0.3, 160.0)
	_expect("oblouk doleva ⇒ curve < 0 (%.2f)" % gl.curve, gl.curve < -0.2)
	_expect("zrcadlová symetrie", absf(gr.curve + gl.curve) < 0.001)
	var extreme := _arc(Vector2(100, 500), Vector2(100, 200), 400.0)
	_expect("zakřivení saturuje na 1", Swipe.analyze(extreme, 0.3, 160.0).curve == 1.0)

func _test_cancel_conditions() -> void:
	var short := _line(Vector2(0, 0), Vector2(0, -T.SWIPE_MIN_LENGTH_PX * 0.5), 4)
	_expect("krátký tah = zrušeno", not Swipe.analyze(short, 0.3, 160.0).ok)
	# dlouhá klikatá dráha, ale tětiva v dead-zone
	var jitter := PackedVector2Array()
	for i in 20:
		jitter.append(Vector2(0, 0 if i % 2 == 0 else 6))
	jitter.append(Vector2(2, 0))
	_expect("tětiva v dead-zone = zrušeno", not Swipe.analyze(jitter, 0.3, 160.0).ok)
	var ok_pts := _line(Vector2(0, 0), Vector2(0, -300), 10)
	_expect("příliš krátké trvání = zrušeno",
			not Swipe.analyze(ok_pts, T.SWIPE_MIN_DURATION * 0.5, 160.0).ok)
	_expect("jediný bod = zrušeno",
			not Swipe.analyze(PackedVector2Array([Vector2.ZERO]), 1.0, 160.0).ok)

## B4: vzorky dráhy nesmí růst s délkou držení prstu.
func _test_point_cap() -> void:
	var pts := PackedVector2Array()
	# mikro-posuny pod SWIPE_SAMPLE_MIN_PX se ignorují
	pts = Swipe.add_point(pts, Vector2(10, 10))
	pts = Swipe.add_point(pts, Vector2(10.5, 10))
	_expect("mikro-posun se nevzorkuje", pts.size() == 1)
	# dlouhý drag: 5000 vzorků po 3 px
	var last := Vector2.ZERO
	for i in 5000:
		last = Vector2(10 + 3.0 * i, 10 + 0.5 * i)
		pts = Swipe.add_point(pts, last)
	_expect("strop vzorků (%d ≤ %d)" % [pts.size(), T.SWIPE_MAX_POINTS],
			pts.size() <= T.SWIPE_MAX_POINTS)
	_expect("první bod zůstává", pts[0] == Vector2(10, 10))
	_expect("poslední bod zůstává", pts[pts.size() - 1] == last)
	# zředěná dráha dá pořád použitelné gesto
	var g: Dictionary = Swipe.analyze(pts, 1.0, 160.0)
	_expect("zředěná dráha se vyhodnotí", g.ok and g.power > 0.0)

# ── pomocníci ─────────────────────────────────────────────────

func _line(a: Vector2, b: Vector2, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		pts.append(a.lerp(b, float(i) / n))
	return pts

## Parabolický oblouk od a do b s max. vyboulením `bulge` v ose x.
func _arc(a: Vector2, b: Vector2, bulge: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		var p := a.lerp(b, t)
		p.x += bulge * 4.0 * t * (1.0 - t)
		pts.append(p)
	return pts

func _expect(label: String, cond: bool) -> void:
	if cond:
		print("  PASS  %s" % label)
	else:
		print("  FAIL  %s" % label)
		_failures += 1
