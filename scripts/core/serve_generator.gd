class_name ServeGenerator
extends RefCounted
## Seedovatelné nadhozy (VOLLEY_PLAN.md §5.1): stejný seed ⇒ stejná sekvence
## míčů — regresní testy, replaye, později daily challenge.
## Čistá třída bez závislostí na scéně.

const T := preload("res://scripts/util/tuning.gd")

var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

## Vrátí {pos: Vector3, vel: Vector3, omega: Vector3}.
## Míč přilétá obloukem zepředu/ze strany, dopadá ~1.5–2.5 m před hráče
## (origin) a přiskáče do kop-zóny. Balistika bez dragu — pro nadhoz stačí,
## drag jen mírně zkrátí oblouk.
func next_serve() -> Dictionary:
	var start := Vector3(
		_rng.randf_range(-2.5, 2.5),
		_rng.randf_range(0.6, 1.4),
		-_rng.randf_range(6.0, 9.0),
	)
	var landing := Vector3(
		_rng.randf_range(-0.5, 0.5),
		T.BALL_RADIUS,
		-_rng.randf_range(1.5, 2.5),
	)
	var flight_time := _rng.randf_range(0.9, 1.4)

	var delta := landing - start
	var vel := Vector3(
		delta.x / flight_time,
		delta.y / flight_time + 0.5 * (-T.GRAVITY.y) * flight_time,
		delta.z / flight_time,
	)
	# lehký náhodný spin, ať odskoky nejsou sterilní
	var spin := Vector3(
		_rng.randf_range(-8.0, 8.0),
		_rng.randf_range(-5.0, 5.0),
		_rng.randf_range(-3.0, 3.0),
	)
	return {"pos": start, "vel": vel, "omega": spin}
