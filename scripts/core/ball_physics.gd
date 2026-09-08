class_name BallPhysics
extends Node3D
## Vlastní integrace letu míče (VOLLEY_PLAN.md §3.2–3.3).
## Godot RigidBody3D nemá Magnusovu sílu, proto semi-implicitní Euler na
## fixed physics ticku (120 Hz, viz project.godot). Žádné závislosti na
## scéně ani autoloadech — instancovatelné headless v testech.

const T := preload("res://scripts/util/tuning.gd")

signal bounced(pos: Vector3, impact_speed: float)
signal ball_stopped

var vel := Vector3.ZERO
var omega := Vector3.ZERO      # spin v rad/s (osa × velikost)
var flying := false            # false = míč čeká (serve/výsledek)
var bounce_count := 0          # odskoky od posledního launch()

var _rolling := false

func launch(start_vel: Vector3, spin: Vector3) -> void:
	vel = start_vel
	omega = spin
	flying = true
	_rolling = false
	bounce_count = 0

func stop() -> void:
	vel = Vector3.ZERO
	omega = Vector3.ZERO
	flying = false
	_rolling = false

func _physics_process(delta: float) -> void:
	if not flying:
		return

	if _rolling:
		_roll(delta)
		return

	# síly: gravitace + drag + Magnus (§3.2)
	var v_len := vel.length()
	var drag := -0.5 * T.RHO * T.CD * T.BALL_AREA * v_len * vel
	var magnus := T.S_COEFF * omega.cross(vel)
	var accel := T.GRAVITY + (drag + magnus) / T.BALL_MASS

	vel += accel * delta
	position += vel * delta
	omega *= exp(-T.SPIN_DECAY * delta)
	_spin_visual(delta)

	if position.y < T.BALL_RADIUS and vel.y < 0.0:
		_bounce()

## Odskok od země (§3.3): restituce + tření + přenos spinu do xz.
func _bounce() -> void:
	position.y = T.BALL_RADIUS
	var impact := absf(vel.y)
	vel.y = -T.RESTITUTION * vel.y

	# rychlost povrchu míče v kontaktním bodě (dole) — topspin táhne dopředu
	var contact_r := Vector3(0, -T.BALL_RADIUS, 0)
	var surface := omega.cross(contact_r)
	var xz := Vector3(vel.x, 0, vel.z) * (1.0 - T.GROUND_FRICTION) \
			- surface * T.BOUNCE_SPIN_TRANSFER
	vel.x = xz.x
	vel.z = xz.z
	omega *= T.BOUNCE_SPIN_RETAIN

	bounce_count += 1
	bounced.emit(position, impact)

	if vel.y < T.BOUNCE_MIN_VY:
		vel.y = 0.0
		_rolling = true

## Kutálení: exponenciální útlum, pod STOP_SPEED míč usne.
func _roll(delta: float) -> void:
	vel *= exp(-T.ROLL_FRICTION * delta)
	position += vel * delta
	position.y = T.BALL_RADIUS
	omega *= exp(-T.ROLL_FRICTION * delta)
	_spin_visual(delta)
	if vel.length() < T.STOP_SPEED:
		stop()
		ball_stopped.emit()

## Vizuální rotace meshe podle spinu — hráč čte faleš z míče, ne z HUD.
func _spin_visual(delta: float) -> void:
	var w := omega.length()
	if w > 0.001:
		rotate(omega / w, w * delta)
