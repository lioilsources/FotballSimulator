extends SceneTree
## End-to-end test herní smyčky (Fáze 1): nahraje main.tscn, počká na
## ideální okamžik kontaktu a kopne přes game_state přesně tak, jako by
## přišel swipe. Ověřuje wiring signálů, převod lokálního rámce do světa,
## freeze-frame (pauza + unpauza) i detekci gólu.
##
##   godot --headless --path . --script res://tests/gameplay_test.gd

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

	if _failures == 0:
		print("=== ALL TESTS PASSED ===")
	else:
		print("=== %d TEST(S) FAILED ===" % _failures)
	quit(0 if _failures == 0 else 1)

func _expect(label: String, cond: bool) -> void:
	if cond:
		print("  PASS  %s" % label)
	else:
		print("  FAIL  %s" % label)
		_failures += 1
