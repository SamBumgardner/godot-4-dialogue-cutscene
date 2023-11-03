extends Control

const END_OF_SENTENCE_PAUSE : float = .15

@export var cutscene : DialogueCutsceneData
@onready var audio_stream_randomizer = $AudioStreamPlayer.stream
@onready var dialogue_display : DialogueDisplay = $DialogueDisplay

var animation_during_step : Array[String]
var current_script_page : int
var dialogue_units : Array[DialogueUnit]
var current_unit_i = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Characters/AnimatedPortrait.sprite_frames = cutscene.characters[0].animations
	audio_stream_randomizer.add_stream(0, cutscene.characters[0].voice, 1)
	
	dialogue_display.dialogue_label.text_revealed.connect(_on_text_revealed, CONNECT_DEFERRED)
	dialogue_display.starting_dialogue_unit.connect(_on_starting_dialogue_unit)
	
	current_script_page = -1
	_attempt_scene_advance()

func _parse_script_page(text : String) -> Array[DialogueUnit]:
	var units : Array[DialogueUnit] = []
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
			units.append(unit)
			starting_point = end_index
			sentence_i += 1
	return units

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_attempt_scene_advance()

func _attempt_scene_advance() -> void:
	# If current step of scene is not complete, go to completion
	# If should start playing next step of scene, initiate next steps
	var can_start_next_page : bool = dialogue_display.attempt_dialogue_advance()
	if can_start_next_page:
		current_script_page += 1
		if current_script_page < cutscene.dialogue_script.size():
			current_unit_i = -1
			dialogue_units = _parse_script_page(cutscene.dialogue_script[current_script_page])
			dialogue_display.display_dialogue(dialogue_units)

func _on_text_revealed():
	$AudioStreamPlayer.play()

func _on_starting_dialogue_unit(starting_step_i : int, is_delay : bool) -> void:
	if is_delay:
		_animate_talking("neutral")
	else:
		current_unit_i += 1
		_animate_talking(dialogue_units[current_unit_i].animation_name)

func _animate_talking(animation_name : String) -> void:
	$Characters/AnimatedPortrait.play(animation_name)

