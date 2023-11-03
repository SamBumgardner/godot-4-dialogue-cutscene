extends NinePatchRect

class_name DialogueDisplay

signal starting_dialogue_unit

const SEC_PER_CHAR : float = .05

@onready var dialogue_label : Label = $TextAnchor/Dialogue
@onready var text_appear_tween : Tween
var _is_delay_step : Array[bool]

func attempt_dialogue_advance() -> bool:
	if text_appear_tween != null and text_appear_tween.is_running():
		text_appear_tween.custom_step(1000)
		return false
	else:
		return true

func display_dialogue(dialogue_units : Array[DialogueUnit]) -> void:
	$DialogueAdvanceArrow.hide()
	
	var text_to_show = ""
	dialogue_label.visible_characters = 0
	_is_delay_step = []
	
	text_appear_tween = create_tween()
	text_appear_tween.step_finished.connect(_dialogue_tween_step_finished, CONNECT_DEFERRED)
	for i in dialogue_units.size():
		var unit : DialogueUnit = dialogue_units[i]
		text_to_show += unit.text
		if unit.delay_before > 0:
			text_appear_tween.tween_interval(unit.delay_before)
			_is_delay_step.push_back(true)
		text_appear_tween.tween_property(
			dialogue_label, "visible_characters", text_to_show.length(), 
			unit.text.length() * SEC_PER_CHAR / unit.speed_mult)
		_is_delay_step.push_back(false)
		if unit.delay_after > 0:
			text_appear_tween.tween_interval(unit.delay_after)
			_is_delay_step.push_back(true)
	
	text_appear_tween.finished.connect($DialogueAdvanceArrow.show, CONNECT_ONE_SHOT)
	
	dialogue_label.text = text_to_show
	starting_dialogue_unit.emit(0, _is_delay_step[0])

func _dialogue_tween_step_finished(finished_step_index : int):
	if text_appear_tween.is_running():
		var next_step_i = finished_step_index + 1
		starting_dialogue_unit.emit(next_step_i, _is_delay_step[next_step_i])
