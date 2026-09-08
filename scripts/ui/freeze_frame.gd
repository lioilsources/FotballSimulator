extends Control
## Freeze-frame kontaktu (VOLLEY_PLAN.md §5.3): 150 ms pauza se zvýrazněným
## kontaktním bodem a vektorem výkopu — hráč se učí PROČ míč letěl, jak letěl.
## process_mode = ALWAYS, takže kreslí i při get_tree().paused.

const T := preload("res://scripts/util/tuning.gd")

var _contact := Vector3.ZERO
var _vel := Vector3.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

## Zapauzuje strom na FREEZE_TIME reálného času a vykreslí kontakt.
func trigger(contact_world: Vector3, vel: Vector3) -> void:
	_contact = contact_world
	_vel = vel
	visible = true
	queue_redraw()
	var tree := get_tree()
	tree.paused = true
	await tree.create_timer(T.FREEZE_TIME, true, false, true).timeout
	tree.paused = false
	visible = false

func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or cam.is_position_behind(_contact):
		return
	var p := cam.unproject_position(_contact)
	var tip := cam.unproject_position(_contact + _vel * 0.04)

	# vektor výkopu se šipkou
	draw_line(p, tip, Color(1.0, 0.9, 0.2), 3.0)
	var dir := (tip - p).normalized()
	var side := Vector2(-dir.y, dir.x)
	draw_line(tip, tip - dir * 12.0 + side * 7.0, Color(1.0, 0.9, 0.2), 3.0)
	draw_line(tip, tip - dir * 12.0 - side * 7.0, Color(1.0, 0.9, 0.2), 3.0)

	# kontaktní bod
	draw_circle(p, 7.0, Color(1.0, 0.25, 0.2))
	draw_arc(p, 13.0, 0.0, TAU, 32, Color(1.0, 0.25, 0.2, 0.7), 2.0)
