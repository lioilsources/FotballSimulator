extends CanvasLayer
## Základní HUD (VOLLEY_PLAN.md §5.5): po kopu `92 km/h · 7.2 ot/s ·
## PERFECT (+12 ms)`, výsledek (GÓL/MIMO/…) uprostřed. Heatmapa a streak
## přijdou ve Fázi 2.

const T := preload("res://scripts/util/tuning.gd")

const RATING_NAMES := {
	ContactModel.Rating.PERFECT: "PERFECT",
	ContactModel.Rating.GOOD: "GOOD",
	ContactModel.Rating.EARLY: "EARLY",
	ContactModel.Rating.LATE: "LATE",
	ContactModel.Rating.MISS: "MISS",
}

@onready var kick_label: Label = $Root/KickLabel
@onready var result_label: Label = $Root/ResultLabel

var _kick_tween: Tween

func show_kick(vel: Vector3, omega: Vector3, rating: int, err_ms: int) -> void:
	kick_label.text = "%d km/h · %.1f ot/s · %s (%+d ms)" % [
		roundi(vel.length() * 3.6),
		omega.length() / TAU,
		RATING_NAMES.get(rating, "?"),
		err_ms,
	]
	_fade_kick_label()

func show_miss(err_ms: int) -> void:
	kick_label.text = "VZDUCH! (%+d ms)" % err_ms
	_fade_kick_label()

func show_result(text: String, color: Color) -> void:
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)

func clear_result() -> void:
	result_label.text = ""

func _fade_kick_label() -> void:
	if _kick_tween != null:
		_kick_tween.kill()
	kick_label.modulate.a = 1.0
	_kick_tween = create_tween()
	_kick_tween.tween_interval(T.HUD_FADE_DELAY)
	_kick_tween.tween_property(kick_label, "modulate:a", 0.0, 0.5)
