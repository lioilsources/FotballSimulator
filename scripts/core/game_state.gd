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
@onready var kicker_view: Node3D = $KickerView

var state := State.SERVE
var _serve_gen: ServeGenerator
var _prev_ball_z := 0.0
var _result_reported := false
var _serve_time := 0.0     # herní čas od začátku serve (nezávislý na time_scale)
var _t_ideal := 0.0        # ideální okamžik kontaktu (z pre-simulace)
var _swung := false        # jeden švih na serve
var _assist := true
var kicker := Kicker.new()  # vizuální fotbalista (gameplay neovlivňuje)

func _ready() -> void:
	_serve_gen = ServeGenerator.new(Tuning.SERVE_SEED)
	_assist = Tuning.ASSIST_DEFAULT
	ball.ball_stopped.connect(_on_ball_stopped)
	ball.bounced.connect(_on_ball_bounced)
	swipe.ball = ball
	swipe.swipe_started.connect(_on_swipe_started)
	swipe.swipe_canceled.connect(_on_swipe_canceled)
	swipe.kick_released.connect(_on_kick_released)
	kicker_view.kicker = kicker
	hud.foot_toggled.connect(_toggle_foot)
	hud.show_foot(kicker.foot)
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
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	_t_ideal = presim_ideal_time(s, dt)
	kicker.on_serve(presim_position_at(s, _t_ideal, dt))
	print("── Serve: start=%v · ideál kontaktu za %.2f s" % [s.pos, _t_ideal])

func _physics_process(delta: float) -> void:
	_serve_time += delta
	kicker.update(delta)

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
			if ball.position.z < -(Tuning.GOAL_DISTANCE + Tuning.FLIGHT_END_BEYOND_GOAL):
				ball.stop()
				_finish_serve("", Color.WHITE)

	_prev_ball_z = ball.position.z

# ── timing okno ───────────────────────────────────────────────

## Pre-simulace serve: po prvním odskoku míč stoupá → vrchol → klesá;
## ideál = průchod IDEAL_KICK_HEIGHT při klesání (§3.5). Slabý odskok
## (nedosáhne té výšky) → ideál = vrchol odskoku. Statická = čistá funkce
## serve → čas, testovaná proti shared/golden.json.
static func presim_ideal_time(s: Dictionary, dt: float) -> float:
	var scratch: BallPhysics = BallPhysics.new()
	scratch.position = s.pos
	scratch.launch(s.vel, s.omega)
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

## Poloha míče v čase t serve (pro postoj fotbalisty u ideálu).
static func presim_position_at(s: Dictionary, t: float, dt: float) -> Vector3:
	var scratch: BallPhysics = BallPhysics.new()
	scratch.position = s.pos
	scratch.launch(s.vel, s.omega)
	var tt := 0.0
	while tt < t - dt / 2.0:
		scratch._physics_process(dt)
		tt += dt
	var pos := scratch.position
	scratch.free()
	return pos

func _on_ball_bounced(_pos: Vector3, _speed: float) -> void:
	if state == State.SERVE and ball.bounce_count == 1:
		state = State.KICK_WINDOW

func _kickable() -> bool:
	return (state == State.SERVE or state == State.KICK_WINDOW) and not _swung

# ── swipe → kop ───────────────────────────────────────────────

func _on_swipe_started() -> void:
	if not _kickable():
		return
	if _assist:
		Engine.time_scale = Tuning.ASSIST_SLOWMO
	kicker.windup()

func _on_swipe_canceled() -> void:
	Engine.time_scale = 1.0
	kicker.cancel_windup()

func _toggle_foot() -> void:
	kicker.foot = Kicker.Foot.LEFT if kicker.foot == Kicker.Foot.RIGHT \
			else Kicker.Foot.RIGHT
	hud.show_foot(kicker.foot)

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
		# vzduch — míč letí dál, serve uzavře druhý dopad; fotbalista kopne
		# do místa, kde měl míč v ideálu být
		var l := offset.limit_length(0.95)
		var u_loc := Vector3(l.x, l.y, sqrt(1.0 - l.length_squared()))
		var u := right * u_loc.x + Vector3.UP * u_loc.y - fwd * u_loc.z
		kicker.strike(kicker.ideal_ball() + u * Tuning.BALL_RADIUS, u,
				fwd * (Tuning.FOOT_SPEED_MAX * power), power)
		hud.show_miss(err_ms)
		return

	var vel: Vector3 = right * res.vel.x + Vector3.UP * res.vel.y - fwd * res.vel.z
	var omega: Vector3 = right * res.omega.x + Vector3.UP * res.omega.y - fwd * res.omega.z
	var contact_dir: Vector3 = right * res.contact_dir.x \
			+ Vector3.UP * res.contact_dir.y - fwd * res.contact_dir.z
	var contact_world: Vector3 = ball.position + Tuning.BALL_RADIUS * contact_dir

	trail.clear_trail()
	ball.launch(vel, omega)
	state = State.FLIGHT
	_result_reported = false
	hud.show_kick(vel, omega, res.rating, err_ms)
	kicker.strike(contact_world, contact_dir, vel, power)
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
			KEY_F:
				_toggle_foot()

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
	kicker.strike(ball.position - dir * Tuning.BALL_RADIUS, -dir, vel, 1.0)
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
	await get_tree().create_timer(Tuning.RESULT_PAUSE).timeout
	_serve()
