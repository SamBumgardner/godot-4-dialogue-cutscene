extends Control

const SEC_PER_CHAR : float = .050
const END_OF_SENTENCE_PAUSE : float = .15

@onready var dialogue_label : Label = $NinePatchRect/TextAnchor/Dialogue
@onready var text_appear_tween : Tween

var dialogue_units : Array[DialogueUnit] = []
var animation_during_step : Array[String] = []

var dialogue_text : String = "|2|This is a sample dialogue. I wonder how we should handle positioning for text that doesn't fill the entire dialogue box. 

|1|With this sizing|.15,0,1,neutral|...|1| we can fit a total of 4 lines. Who knows how well this would work."

# Called when the node enters the scene tree for the first time.
func _ready():
	_display_dialogue(dialogue_text)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		attempt_dialogue_advance()

func attempt_dialogue_advance():
	if text_appear_tween != null and text_appear_tween.is_running():
		text_appear_tween.custom_step(1000)
	elif text_appear_tween != null and !text_appear_tween.is_running():
		_display_dialogue(dialogue_text)

func _display_dialogue(text : String) -> void:
	$NinePatchRect/DialogueAdvanceArrow.hide()
	
	_parse_dialogue(text)
	animation_during_step.clear()
	var text_to_show = ""
	dialogue_label.visible_characters = 0
	
	text_appear_tween = create_tween()
	text_appear_tween.step_finished.connect(_dialogue_tween_step_finished)
	for i in dialogue_units.size():
		var unit : DialogueUnit = dialogue_units[i]
		text_to_show += unit.text
		if unit.delay_before > 0:
			animation_during_step.push_back("neutral")
			text_appear_tween.tween_interval(unit.delay_before)
		animation_during_step.push_back(unit.animation_name)
		text_appear_tween.tween_property(
			dialogue_label, "visible_characters", text_to_show.length(), 
			unit.text.length() * SEC_PER_CHAR / unit.speed_mult)
		if unit.delay_after > 0:
			animation_during_step.push_back("neutral")
			text_appear_tween.tween_interval(unit.delay_after)
	
	text_appear_tween.finished.connect($NinePatchRect/DialogueAdvanceArrow.show)
	
	dialogue_label.text = text_to_show
	animation_during_step.push_back("default")
	_animate_talking(animation_during_step[0])

func _dialogue_tween_step_finished(finished_step_index : int) -> void:
	_animate_talking(animation_during_step[finished_step_index + 1])

func _animate_talking(animation_name : String) -> void:
	$NinePatchRect/DialogueEdgeAnchor/AnimatedPortrait.play(animation_name)

func _parse_dialogue(text : String) -> void:
	dialogue_units.clear()
	var meta_and_text : PackedStringArray = text.split("|", false)
	for i in range(0, meta_and_text.size(), 2):
		var regex = RegEx.new()
		regex.compile("[^.]*[.!?]+")
		var sentences = regex.search_all(meta_and_text[i + 1])
		var starting_point = 0
		var sentence_i = 0
		while starting_point < meta_and_text[i + 1].length() - 1:
			var end_index = sentences[sentence_i].get_end() if sentences.size() != sentence_i else meta_and_text[i + 1].length()
			var unit = DialogueUnit.new(meta_and_text[i + 1].substr(starting_point, end_index - starting_point), meta_and_text[i])
			unit.delay_before = 0
			unit.delay_after = END_OF_SENTENCE_PAUSE
			dialogue_units.append(unit)
			starting_point = end_index
			sentence_i += 1

class DialogueUnit extends RefCounted:
	const DEFAULT_SPEED_MULTIPLIER = 1
	
	var text : String
	var delay_before : float = 0
	var speed_mult : float = DEFAULT_SPEED_MULTIPLIER
	var delay_after : float = 0
	var animation_name : String = "talking"
	
	func _init(
			i_text : String, 
			metadata : String):
		text = i_text
		var split_metadata = metadata.split(",")
		for i in split_metadata.size():
			var raw_data = split_metadata[i]
			match i:
				0: speed_mult = float(raw_data)
				1: delay_before = float(raw_data)
				2: delay_after = float(raw_data)
				3: animation_name = raw_data
