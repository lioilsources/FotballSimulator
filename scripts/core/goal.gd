extends Node3D
## Brána postavená z tuningu (VOLLEY_PLAN.md §2): tyče a břevno vznikají
## v _ready() z GOAL_HALF_WIDTH / GOAL_HEIGHT / POST_RADIUS a celá brána se
## posune na -GOAL_DISTANCE. Scéna tak nemůže rozjet vizuál vůči detekci
## gólu v game_state — jediný zdroj pravdy je tuning.gd. Ve Fázi 2 sem
## přibudou kolize s tyčemi (stejná geometrie).

const T := preload("res://scripts/util/tuning.gd")

@export var material: Material

func _ready() -> void:
	position.z = -T.GOAL_DISTANCE
	# vnitřní hrana tyče = GOAL_HALF_WIDTH, střed tyče o poloměr dál
	var post_x := T.GOAL_HALF_WIDTH + T.POST_RADIUS
	_add_post("PostLeft", Vector3(-post_x, T.GOAL_HEIGHT * 0.5, 0), T.GOAL_HEIGHT,
			Vector3.ZERO)
	_add_post("PostRight", Vector3(post_x, T.GOAL_HEIGHT * 0.5, 0), T.GOAL_HEIGHT,
			Vector3.ZERO)
	# spodní hrana břevna = GOAL_HEIGHT; délka přes vnější hrany tyčí
	_add_post("Crossbar", Vector3(0, T.GOAL_HEIGHT + T.POST_RADIUS, 0),
			2.0 * (post_x + T.POST_RADIUS), Vector3(0, 0, PI / 2.0))

func _add_post(post_name: String, pos: Vector3, length: float,
		rot: Vector3) -> void:
	var post := CSGCylinder3D.new()
	post.name = post_name
	post.radius = T.POST_RADIUS
	post.height = length
	post.position = pos
	post.rotation = rot
	post.material = material
	add_child(post)
