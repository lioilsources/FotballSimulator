extends Control
## Swipe gesto → KickIntent (VOLLEY_PLAN.md §4). Overlay míč dole uprostřed
## zrcadlí rotaci reálného míče (hráč vidí faleš). Touch-down na overlay
## = volba kontaktního bodu, dráha prstu = zakřivení, rychlost = síla,
## puštění = timing (timing_error počítá game_state proti ideálu).

const T := preload("res://scripts/util/tuning.gd")

signal swipe_started
signal swipe_canceled
signal kick_released(contact_offset: Vector2, swing_curve: float, power: float)

var ball: Node3D = null        # nastavuje game_state (kvůli zrcadlení rotace)
var enabled := true:
	set(v):
		enabled = v
		if not v and _tracking:
			# vypnutí uprostřed gesta = zrušené gesto; game_state na to
			# musí zareagovat (zrušit assist slow-mo), release už nepřijde
			_tracking = false
			swipe_canceled.emit()

var _tracking := false
var _pts := PackedVector2Array()
var _t_start := 0.0
var _contact_offset := Vector2.ZERO
var _dpi := 160.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dpi := DisplayServer.screen_get_dpi()
	_dpi = float(dpi) if dpi > 0 else 160.0

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_try_start(event.position)
		elif _tracking:
			_finish(event.position)
	elif event is InputEventScreenDrag and _tracking:
		_pts = add_point(_pts, event.position)

func _try_start(pos: Vector2) -> void:
	var center := _overlay_center()
	var radius := _overlay_radius()
	var off := pos - center
	if off.length() > radius:
		return  # gesto začíná jen na overlay míči
	_tracking = true
	_pts = PackedVector2Array([pos])
	_t_start = Time.get_ticks_msec() / 1000.0
	# obrazovkové y roste dolů → na míči je +y nahoře
	_contact_offset = (Vector2(off.x, -off.y) / radius).limit_length(1.0)
	swipe_started.emit()

func _finish(pos: Vector2) -> void:
	_tracking = false
	_pts.append(pos)
	var duration := Time.get_ticks_msec() / 1000.0 - _t_start
	var g := analyze(_pts, duration, _dpi)
	if not g.ok:
		swipe_canceled.emit()
		return
	kick_released.emit(_contact_offset, g.curve, g.power)

# ── čistá geometrie gesta (statické, headless testovatelné) ───

## Přidá vzorek dráhy prstu. Mikro-posuny pod SWIPE_SAMPLE_MIN_PX se
## zahazují; při přetečení SWIPE_MAX_POINTS se dráha zředí na polovinu
## (první a poslední bod zůstávají), takže paměť ani _draw nerostou
## s délkou držení prstu.
static func add_point(pts: PackedVector2Array, pos: Vector2) -> PackedVector2Array:
	if pts.size() > 0 \
			and pts[pts.size() - 1].distance_to(pos) < T.SWIPE_SAMPLE_MIN_PX:
		return pts
	pts.append(pos)
	if pts.size() <= T.SWIPE_MAX_POINTS:
		return pts
	var thinned := PackedVector2Array()
	for i in range(0, pts.size(), 2):
		thinned.append(pts[i])
	if thinned[thinned.size() - 1] != pts[pts.size() - 1]:
		thinned.append(pts[pts.size() - 1])
	return thinned

## Vyhodnotí dokončené gesto → {ok, power, curve}. ok = false pro tah
## kratší než SWIPE_MIN_LENGTH_PX, tětivu v dead-zone nebo tah kratší než
## SWIPE_MIN_DURATION. Souřadnice jsou obrazovkové (y dolů).
static func analyze(pts: PackedVector2Array, duration: float, dpi: float) -> Dictionary:
	if pts.size() < 2:
		return {"ok": false, "power": 0.0, "curve": 0.0}
	var path_len := 0.0
	for i in range(1, pts.size()):
		path_len += pts[i].distance_to(pts[i - 1])
	var chord := pts[pts.size() - 1] - pts[0]

	if path_len < T.SWIPE_MIN_LENGTH_PX or chord.length() < T.SWIPE_DEADZONE_PX \
			or duration < T.SWIPE_MIN_DURATION:
		return {"ok": false, "power": 0.0, "curve": 0.0}

	# síla: rychlost prstu normalizovaná na DPI (px/s → in/s)
	var power := clampf(
			(path_len / duration) / dpi / T.SWIPE_POWER_FULL_INS, 0.0, 1.0)

	# zakřivení: max podepsaná kolmá odchylka od tětivy / půlka tětivy;
	# kladné = oblouk doprava vůči směru tahu
	var dir := chord.normalized()
	var max_dev := 0.0
	for p in pts:
		var rel := p - pts[0]
		var dev := dir.x * rel.y - dir.y * rel.x
		if absf(dev) > absf(max_dev):
			max_dev = dev
	var curve := clampf(max_dev / (chord.length() * 0.5), -1.0, 1.0)

	return {"ok": true, "power": power, "curve": curve}

# ── kreslení overlay ──────────────────────────────────────────

func _overlay_radius() -> float:
	return size.x * T.OVERLAY_BALL_SCREEN_FRAC * 0.5

func _overlay_center() -> Vector2:
	return Vector2(size.x * 0.5, size.y - _overlay_radius() - 40.0)

func _draw() -> void:
	var center := _overlay_center()
	var radius := _overlay_radius()
	var alpha := 1.0 if enabled else 0.35

	draw_circle(center, radius, Color(1, 1, 1, 0.07 * alpha))
	draw_arc(center, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.35 * alpha), 2.0)

	# zrcadlení rotace: tělesové osy míče promítnuté na přivrácenou polokouli
	if ball != null:
		var basis := ball.global_transform.basis
		for axis in [basis.x, -basis.x, basis.z, -basis.z]:
			if axis.z > 0.15:  # kamera kouká -z → vidíme +z stranu
				var dot_pos := center + Vector2(axis.x, -axis.y) * radius * 0.8
				draw_circle(dot_pos, radius * 0.06,
						Color(0.1, 0.1, 0.14, 0.55 * alpha))

	if _tracking:
		var marker := center + Vector2(_contact_offset.x, -_contact_offset.y) * radius
		draw_circle(marker, 9.0, Color(1.0, 0.5, 0.1, 0.9))
		if _pts.size() >= 2:
			draw_polyline(_pts, Color(0.4, 0.9, 1.0, 0.6), 3.0)
