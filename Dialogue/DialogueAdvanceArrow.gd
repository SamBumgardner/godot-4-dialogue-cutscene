extends TextureRect

@onready var start_position : Vector2 = position
var animating_tween : Tween

func _ready():
	animating_tween = _create_bounce_tween()
	visibility_changed.connect(_reset_tween)

func _reset_tween() -> void:
	position = start_position
	animating_tween.stop()
	animating_tween.play()

func _create_bounce_tween() -> Tween:
	const BOUNCE_Y_CHANGE = Vector2(0, 15)
	const BOUNCE_DURATION = .5
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", start_position + BOUNCE_Y_CHANGE, BOUNCE_DURATION)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", start_position, BOUNCE_DURATION)
	tween.set_loops(-1)
	return tween

