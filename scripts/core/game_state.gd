extends Node3D
## Herní FSM (VOLLEY_PLAN.md §2): SERVE → KICK_WINDOW → FLIGHT → RESULT.
## Fáze 1: swipe → ContactModel → let; timing_error se měří proti ideálnímu
## okamžiku z pre-simulace serve trajektorie (fyzika je deterministická,
## takže ideál známe dopředu). Debug kopy 1/2/3 zůstávají, A přepíná assist.

enum State { SERVE, KICK_WINDOW, FLIGHT, RESULT }

@onready var ball: BallPhysics = $Ball
@onready var trail: Node = $Ball/Trail
@onready var hud: CanvasLayer = $HUD
@onready var freeze: Control = $HUD/FreezeFrame
@onready var swipe: Control = $SwipeOverlay

var state := State.SERVE
var _serve_gen: ServeGenerator
var _prev_ball_z := 0.0
var _result_reported := false
var _serve_time := 0.0     # herní čas od začátku serve (nezávislý na time_scale)
var _t_ideal := 0.0        # ideální okamžik kontaktu (z pre-simulace)
var _swung := false        # jeden švih na serve
var _assist := true

func _ready() -> void:
	_serve_gen = ServeGenerator.new(Tuning.SERVE_SEED)
	_assist = Tuning.ASSIST_DEFAULT
	ball.ball_stopped.connect(_on_ball_stopped)
	ball.bounced.connect(_on_ball_bounced)
	swipe.ball = ball
	swipe.swipe_started.connect(_on_swipe_started)
	swipe.swipe_canceled.connect(_on_swipe_canceled)
	swipe.kick_released.connect(_on_kick_released)
	_serve()

func _serve() -> void:
	state = State.SERVE
	_swung = false
	_result_reported = false
	_serve_time = 0.0
	swipe.enabled = true
	hud.clear_result()
	trail.clear_trail()
	var s: Dictionary = _serve_gen.next_serve()
	ball.position = s.pos
	ball.launch(s.vel, s.omega)
	_prev_ball_z = ball.position.z
	_t_ideal = _presim_ideal_time(s)
	print("── Serve: start=%v · ideál kontaktu za %.2f s" % [s.pos, _t_ideal])

func _physics_process(delta: float) -> void:
	_serve_time += delta

	match state:
		State.KICK_WINDOW, State.SERVE:
			# druhý dopad = šance pryč (volej se kope před ním)
			if ball.bounce_count >= 2:
				_finish_serve("POZDĚ" if not _swung else "MIMO",
						Color(1.0, 0.6, 0.2))
		State.FLIGHT:
			if not _result_reported:
				_check_goal_crossing()
			# míč daleko za bránou už nemá co ukázat
			if ball.position.z < -(Tuning.GOAL_DISTANCE + 10.0):
				ball.stop()
				_finish_serve("", Color.WHITE)

	_prev_ball_z = ball.position.z

# ── timing okno ───────────────────────────────────────────────

## Pre-simulace serve: po prvním odskoku míč stoupá → vrchol → klesá;
## ideál = průchod IDEAL_KICK_HEIGHT při klesání (§3.5). Slabý odskok
## (nedosáhne té výšky) → ideál = vrchol odskoku.
func _presim_ideal_time(s: Dictionary) -> float:
	var scratch: BallPhysics = BallPhysics.new()
	scratch.position = s.pos
	scratch.launch(s.vel, s.omega)
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var t := 0.0
	var apex_t := 0.0
	var apex_h := 0.0
	while t < 8.0 and scratch.flying and scratch.bounce_count < 2:
		scratch._physics_process(dt)
		t += dt
		if scratch.bounce_count == 1:
			if scratch.position.y > apex_h:
				apex_h = scratch.position.y
				apex_t = t
			if scratch.vel.y < 0.0 and scratch.position.y <= Tuning.IDEAL_KICK_HEIGHT:
				scratch.free()
				return t
	scratch.free()
	return apex_t if apex_t > 0.0 else t

func _on_ball_bounced(_pos: Vector3, _speed: float) -> void:
	if state == State.SERVE and ball.bounce_count == 1:
		state = State.KICK_WINDOW

func _kickable() -> bool:
	return (state == State.SERVE or state == State.KICK_WINDOW) and not _swung

# ── swipe → kop ───────────────────────────────────────────────

func _on_swipe_started() -> void:
	if _kickable() and _assist:
		Engine.time_scale = Tuning.ASSIST_SLOWMO

func _on_swipe_canceled() -> void:
	Engine.time_scale = 1.0

func _on_kick_released(offset: Vector2, curve: float, power: float) -> void:
	Engine.time_scale = 1.0
	if not _kickable():
		return
	_swung = true
	swipe.enabled = false

	var err := _serve_time - _t_ideal

	# lokální rámec kopu (-z na bránu) ⇄ svět
	var fwd := Vector3(0, 0, -Tuning.GOAL_DISTANCE) - ball.position
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	var ball_vel_local := Vector3(ball.vel.dot(right), ball.vel.y, -ball.vel.dot(fwd))

	var res: Dictionary = ContactModel.compute_kick(offset, curve, power, err,
			ball_vel_local)
	var err_ms := roundi(err * 1000.0)

	if not res.hit:
		# vzduch — míč letí dál, serve uzavře druhý dopad
		hud.show_miss(err_ms)
		return

	var vel: Vector3 = right * res.vel.x + Vector3.UP * res.vel.y - fwd * res.vel.z
	var omega: Vector3 = right * res.omega.x + Vector3.UP * res.omega.y - fwd * res.omega.z
	var contact_world: Vector3 = ball.position + Tuning.BALL_RADIUS \
			* (right * res.contact_dir.x + Vector3.UP * res.contact_dir.y
					- fwd * res.contact_dir.z)

	trail.clear_trail()
	ball.launch(vel, omega)
	state = State.FLIGHT
	_result_reported = false
	hud.show_kick(vel, omega, res.rating, err_ms)
	freeze.trigger(contact_world, vel)

# ── debug kopy (Fáze 0, zůstávají pro ladění) ────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_debug_kick(Vector3.ZERO)
			KEY_2:
				_debug_kick(Vector3(0, Tuning.DEBUG_SIDESPIN, 0))
			KEY_3:
				# topspin pro let směrem -z = rotace kolem -x
				_debug_kick(Vector3(-Tuning.DEBUG_TOPSPIN, 0, 0))
			KEY_A:
				_assist = not _assist
				print("Assist slow-mo: %s" % ("ON" if _assist else "OFF"))

func _debug_kick(spin: Vector3) -> void:
	if state == State.FLIGHT:
		return
	state = State.FLIGHT
	_result_reported = false
	_swung = true
	swipe.enabled = false
	trail.clear_trail()

	var to_goal := Vector3(0, 0, -Tuning.GOAL_DISTANCE) - ball.position
	to_goal.y = 0.0
	var dir := to_goal.normalized()
	var angle := deg_to_rad(Tuning.DEBUG_KICK_ANGLE_DEG)
	var vel := dir * Tuning.DEBUG_KICK_SPEED * cos(angle) \
			+ Vector3.UP * Tuning.DEBUG_KICK_SPEED * sin(angle)
	ball.launch(vel, spin)
	print("Debug kop: %.0f m/s, spin=%v" % [vel.length(), spin])

# ── výsledky ──────────────────────────────────────────────────

## Průlet rovinou brány → GÓL / MIMO (tyč a síť řeší Fáze 2).
func _check_goal_crossing() -> void:
	var plane_z := -Tuning.GOAL_DISTANCE
	if _prev_ball_z > plane_z and ball.position.z <= plane_z:
		var dt := get_physics_process_delta_time()
		var t := (plane_z - _prev_ball_z) / (ball.position.z - _prev_ball_z)
		var cross_x := lerpf(ball.position.x - ball.vel.x * dt, ball.position.x, t)
		var cross_y := lerpf(ball.position.y - ball.vel.y * dt, ball.position.y, t)
		_result_reported = true
		if absf(cross_x) < Tuning.GOAL_HALF_WIDTH and cross_y < Tuning.GOAL_HEIGHT:
			hud.show_result("GÓL!", Color(0.3, 1.0, 0.4))
			print("GÓL!  (%.2f, %.2f) · %.0f km/h" % [cross_x, cross_y, ball.vel.length() * 3.6])
		else:
			hud.show_result("MIMO", Color(1.0, 0.35, 0.3))
			print("MIMO  (%.2f, %.2f)" % [cross_x, cross_y])

func _on_ball_stopped() -> void:
	if state == State.FLIGHT and not _result_reported:
		hud.show_result("NEDOLETĚL", Color(1.0, 0.6, 0.2))
	_finish_serve("", Color.WHITE)

## Uzavře rozehrávku (s volitelnou hláškou) a po pauze rozehraje další míč.
func _finish_serve(msg: String, color: Color) -> void:
	if state == State.RESULT:
		return
	state = State.RESULT
	# hráč mohl držet prst (assist slow-mo) — bez release by time_scale
	# zůstal 0.6 přes pauzu i další serve
	Engine.time_scale = 1.0
	swipe.enabled = false
	if msg != "":
		hud.show_result(msg, color)
	await get_tree().create_timer(1.4).timeout
	_serve()
