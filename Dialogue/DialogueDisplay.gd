extends NinePatchRect

class_name DialogueDisplay

signal starting_dialogue_unit

const SEC_PER_CHAR : float = .05

@onready var dialogue_label : Label = $TextAnchor/Dialogue
@onready var text_appear_tween : Tween

var current_dialogue_unit : int

func reset() -> void:
	dialogue_label.text = ""
	$DialogueAdvanceArrow.hide()

func attempt_dialogue_advance() -> bool:
	if text_appear_tween != null and text_appear_tween.is_running():
		text_appear_tween.custom_step(1000)
		return false
	else:
		return true

func display_dialogue(dialogue_units : Array[DialogueUnit]) -> void:
	$DialogueAdvanceArrow.hide()
	
	current_dialogue_unit = -1
	var text_to_show = ""
	dialogue_label.visible_characters = 0
	
	text_appear_tween = create_tween()
	for i in dialogue_units.size():
		var unit : DialogueUnit = dialogue_units[i]
		text_to_show += unit.text
		if unit.delay_before > 0:
			text_appear_tween.tween_interval(unit.delay_before)
		text_appear_tween.tween_callback(_starting_new_dialogue_unit)
		text_appear_tween.tween_property(
			dialogue_label, "visible_characters", text_to_show.length(), 
			unit.text.length() * SEC_PER_CHAR / unit.speed_mult)
		if unit.delay_after > 0:
			text_appear_tween.tween_interval(unit.delay_after)
	
	text_appear_tween.finished.connect($DialogueAdvanceArrow.show, CONNECT_ONE_SHOT)
	
	dialogue_label.text = text_to_show

func _starting_new_dialogue_unit():
		current_dialogue_unit += 1
		starting_dialogue_unit.emit(current_dialogue_unit)
