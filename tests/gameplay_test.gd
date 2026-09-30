extends SceneTree
## End-to-end test herní smyčky (Fáze 1): nahraje main.tscn, počká na
## ideální okamžik kontaktu a kopne přes game_state přesně tak, jako by
## přišel swipe. Ověřuje wiring signálů, převod lokálního rámce do světa,
## freeze-frame (pauza + unpauza) i detekci gólu. Druhá rozehrávka:
## regrese B1 (držený prst přes konec serve nesmí nechat slow-mo) a
## geometrie brány z tuningu (B3).
##
##   godot --headless --path . --script res://tests/gameplay_test.gd

const T := preload("res://scripts/util/tuning.gd")

var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	print("=== FotballSimulator — gameplay_test (Fáze 1) ===")
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame

	# počkat na kop-okno (po prvním odskoku) a ideální timing
	var deadline := Time.get_ticks_msec() + 8000
	while main.state != main.State.KICK_WINDOW and Time.get_ticks_msec() < deadline:
		await physics_frame
	_expect("dosažen stav KICK_WINDOW", main.state == main.State.KICK_WINDOW)

	while main._serve_time < main._t_ideal and Time.get_ticks_msec() < deadline:
		await physics_frame

	# perfektní nízký volej doprostřed brány (stejný intent jako v contact_test)
	main._on_kick_released(Vector2(0, -0.12), 0.0, 1.0)
	_expect("kop proběhl → FLIGHT", main.state == main.State.FLIGHT)

	# freeze-frame drží pauzu jen chvíli reálného času
	_expect("freeze-frame pauznul strom", paused)

	deadline = Time.get_ticks_msec() + 8000
	while main.state != main.State.RESULT and Time.get_ticks_msec() < deadline:
		await physics_frame
	_expect("strom se odpauzoval", not paused)
	_expect("rozehrávka došla do RESULT", main.state == main.State.RESULT)

	var result_text: String = main.get_node("HUD/Root/ResultLabel").text
	_expect("výsledek je GÓL! (bylo: \"%s\")" % result_text, result_text == "GÓL!")

	_check_goal_geometry(main)
	await _check_stuck_slowmo(main)

	if _failures == 0:
		print("=== ALL TESTS PASSED ===")
	else:
		print("=== %d TEST(S) FAILED ===" % _failures)
	quit(0 if _failures == 0 else 1)

## B3: brána stojí na -GOAL_DISTANCE a její rozměry sedí na tuning.
func _check_goal_geometry(main: Node) -> void:
	var goal: Node3D = main.get_node("Pitch/Goal")
	_expect("brána na -GOAL_DISTANCE", is_equal_approx(goal.position.z, -T.GOAL_DISTANCE))
	var left: Node3D = goal.get_node("PostLeft")
	var right: Node3D = goal.get_node("PostRight")
	var bar: Node3D = goal.get_node("Crossbar")
	_expect("vnitřní hrany tyčí = ±GOAL_HALF_WIDTH",
			is_equal_approx(left.position.x + T.POST_RADIUS, -T.GOAL_HALF_WIDTH)
			and is_equal_approx(right.position.x - T.POST_RADIUS, T.GOAL_HALF_WIDTH))
	_expect("spodní hrana břevna = GOAL_HEIGHT",
			is_equal_approx(bar.position.y - T.POST_RADIUS, T.GOAL_HEIGHT))

## B1: touch-down v kop-okně zapne assist slow-mo; když serve vyprší
## druhým dopadem bez puštění prstu, time_scale se musí vrátit na 1.0.
func _check_stuck_slowmo(main: Node) -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while main.state != main.State.KICK_WINDOW and Time.get_ticks_msec() < deadline:
		await physics_frame
	_expect("druhá rozehrávka: KICK_WINDOW", main.state == main.State.KICK_WINDOW)

	var swipe: Control = main.get_node("SwipeOverlay")
	swipe._try_start(swipe._overlay_center())
	_expect("touch-down zapnul slow-mo", is_equal_approx(Engine.time_scale, T.ASSIST_SLOWMO))

	deadline = Time.get_ticks_msec() + 15000
	while main.state != main.State.RESULT and Time.get_ticks_msec() < deadline:
		await physics_frame
	_expect("serve vypršel bez release → RESULT", main.state == main.State.RESULT)
	_expect("time_scale zpět na 1.0 (bylo %.2f)" % Engine.time_scale,
			is_equal_approx(Engine.time_scale, 1.0))
	_expect("swipe už netrackuje", not swipe._tracking)

func _expect(label: String, cond: bool) -> void:
	if cond:
		print("  PASS  %s" % label)
	else:
		print("  FAIL  %s" % label)
		_failures += 1
