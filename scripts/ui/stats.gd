extends CanvasLayer
## Základní HUD (VOLLEY_PLAN.md §5.5): po kopu `92 km/h · 7.2 ot/s ·
## PERFECT (+12 ms)`, výsledek (GÓL/MIMO/…) uprostřed. Heatmapa a streak
## přijdou ve Fázi 2. Texty jsou klíče z `res://l10n/strings.csv`.

const T := preload("res://scripts/util/tuning.gd")

const RATING_NAMES := {
	ContactModel.Rating.PERFECT: "RATING_PERFECT",
	ContactModel.Rating.GOOD: "RATING_GOOD",
	ContactModel.Rating.EARLY: "RATING_EARLY",
	ContactModel.Rating.LATE: "RATING_LATE",
	ContactModel.Rating.MISS: "RESULT_MISS",
}

@onready var kick_label: Label = $Root/KickLabel
@onready var result_label: Label = $Root/ResultLabel

var _kick_tween: Tween

func show_kick(vel: Vector3, omega: Vector3, rating: int, err_ms: int) -> void:
	kick_label.text = tr("KICK_STATS").format({
		"speed": roundi(vel.length() * 3.6),
		"spin": "%.1f" % (omega.length() / TAU),
		"rating": tr(RATING_NAMES.get(rating, "RESULT_MISS")),
		"ms": "%+d" % err_ms,
	})
	_fade_kick_label()

func show_miss(err_ms: int) -> void:
	kick_label.text = tr("KICK_AIR").format({"ms": "%+d" % err_ms})
	_fade_kick_label()

## [param key] = klíč překladu (RESULT_GOAL, …).
func show_result(key: String, color: Color) -> void:
	result_label.text = tr(key)
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
