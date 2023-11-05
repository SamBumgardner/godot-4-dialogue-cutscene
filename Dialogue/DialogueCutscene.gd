extends Control

signal cutscene_finished

const END_OF_SENTENCE_PAUSE : float = .15

@export var cutscene : DialogueCutsceneData
@onready var audio_stream_randomizer : AudioStreamRandomizer = $AudioStreamPlayer.stream
@onready var dialogue_display : DialogueDisplay = $NameTag/DialogueDisplay

var characters : Dictionary

var current_script_page : int
var dialogue_units : Array[DialogueUnit]
var current_unit_i = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for character in cutscene.characters:
		characters[character.name] = character
	
	dialogue_display.dialogue_label.non_whitespace_char_revealed.connect(_on_text_revealed, CONNECT_DEFERRED)
	dialogue_display.dialogue_label.is_talking_changed.connect(_on_is_talking_changed, CONNECT_DEFERRED)
	dialogue_display.starting_dialogue_unit.connect(_on_starting_dialogue_unit)
	current_script_page = -1
	_attempt_scene_advance()

func _parse_script_page(text : String) -> Array[DialogueUnit]:
	var units : Array[DialogueUnit] = []
	var meta_and_text : PackedStringArray = text.split("|", false)
	for i in range(1, meta_and_text.size(), 2):
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
			_change_displayed_character(cutscene.dialogue_script[current_script_page].get_slice("|", 0))
			dialogue_units = _parse_script_page(cutscene.dialogue_script[current_script_page])
			dialogue_display.display_dialogue(dialogue_units)
		else:
			cutscene_finished.emit()

func _on_text_revealed():
	$AudioStreamPlayer.play()

func _on_starting_dialogue_unit(starting_step_i : int) -> void:
	current_unit_i = starting_step_i

func _on_is_talking_changed(is_talking : bool) -> void:
	if !is_talking:
		_animate_talking("neutral")
	else:
		_animate_talking(dialogue_units[current_unit_i].animation_name)

func _animate_talking(animation_name : String) -> void:
	$Characters/AnimatedPortrait.play(animation_name)

func _change_displayed_character(name : String) -> void:
	$Characters/AnimatedPortrait.sprite_frames = characters[name].animations
	if audio_stream_randomizer.streams_count > 0:
		audio_stream_randomizer.remove_stream(0)
	audio_stream_randomizer.add_stream(0, characters[name].voice, 1)
