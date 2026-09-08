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
		if not v:
			_tracking = false

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
		_pts.append(event.position)

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

	var path_len := 0.0
	for i in range(1, _pts.size()):
		path_len += _pts[i].distance_to(_pts[i - 1])
	var chord := _pts[_pts.size() - 1] - _pts[0]

	if path_len < T.SWIPE_MIN_LENGTH_PX or chord.length() < T.SWIPE_DEADZONE_PX \
			or duration < 0.02:
		swipe_canceled.emit()
		return

	# síla: rychlost prstu normalizovaná na DPI (px/s → in/s)
	var power := clampf(
			(path_len / duration) / _dpi / T.SWIPE_POWER_FULL_INS, 0.0, 1.0)

	# zakřivení: max podepsaná kolmá odchylka od tětivy / půlka tětivy;
	# kladné = oblouk doprava vůči směru tahu
	var dir := chord.normalized()
	var max_dev := 0.0
	for p in _pts:
		var rel := p - _pts[0]
		var dev := dir.x * rel.y - dir.y * rel.x
		if absf(dev) > absf(max_dev):
			max_dev = dev
	var curve := clampf(max_dev / (chord.length() * 0.5), -1.0, 1.0)

	kick_released.emit(_contact_offset, curve, power)

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
