class_name DialogueCutscene
extends Control

# ======= #
# Signals #
# ======= #
## Emitted when the cutscene is completed
## Typically when attempting to advance the cutscene while on the final script page.
signal cutscene_finished

# ========= #
# Constants #
# ========= #
## Time to pause after displaying punctuation (in seconds)
## Used when parsing script pages into arrays of [DialogueUnit]
const END_OF_SENTENCE_PAUSE : float = .15

## Duration of fade visual effect (in seconds) when displaying / hiding cutscene resources
const FADE_DURATION : float = .25

# ================ #
# Exported Members #
# ================ #
## Currently loaded cutscene. 
## Set value to load data, then call [method fade_in)] to reveal nodes & begin the cutscene
@export var cutscene : DialogueCutsceneData:
	set = init_cutscene

# =============== #
# Private Members #
# =============== #
## Contains all [DialogueCharacter]s needed in the current [member cutscene]
var _characters : Dictionary

var _current_script_page : int
## Array of [DialogueUnit] parsed from the cutscene's current script "page"
## Content generated via [method _parse_script_page] when advancing the scene via [method _attempt_scene_advance]
var _dialogue_units : Array[DialogueUnit]

## index of [DialogueUnit] currently being revealed in the subordinate [DialogueDisplay].
## Used to coordinate animations with progression of [DialogueUnits] while displaying script pages.
var _current_unit_i = 0

## tracks if the cutscene is in the process of "closing" and fading out.
## Used to prevent interruptions / issues caused by repeated attempts to close the cutscene.
var _is_closing : bool = false

# ================ #
# On-Ready Members #
# ================ #
@onready var audio_stream_randomizer : AudioStreamRandomizer = $AudioStreamPlayer.stream
@onready var dialogue_display : DialogueDisplay = $DialogueContainer/DialogueDisplay
@onready var character_portrait : AnimatedSprite2D = $Characters/Portrait
@onready var character_mouth : AnimatedSprite2D = $Characters/Portrait/AnimatedMouth

# ======================== #
# Built-in Virtual Methods # 
# ======================== #
## Constructor
## Optionally sets [member cutscene] to [param starting_cutscene], initializing it in the process.
func _init(starting_cutscene : DialogueCutsceneData = null):
	cutscene = starting_cutscene

## Connects events needed to coordinate timing of text reveal and audio / visual actions
## If [member cutscene] has a non-null value, initializes data to prepare to play that cutscene.
func _ready():
	dialogue_display.dialogue_label.non_whitespace_char_revealed.connect(_on_text_revealed, CONNECT_DEFERRED)
	dialogue_display.dialogue_label.is_talking_changed.connect(_on_is_talking_changed, CONNECT_DEFERRED)
	dialogue_display.starting_dialogue_unit.connect(_on_starting_dialogue_unit)
	
	init_cutscene(cutscene)

## Consumes "ui_accept pressed" input events.
## Attempts to advance the scene. See [method _attempt_scene_advance] for further information.
func _input(event):
	if event.is_action_pressed("ui_accept"):
		_attempt_scene_advance()

# ============== #
# Public Methods #
# ============== #
## Uses provided [param cutscene_data] to set internal variables.
## Must be called (explicitly or implicitly via set [member cutscene]) before attempting [method open_cutscene]
func init_cutscene(cutscene_data : DialogueCutsceneData):
	cutscene = cutscene_data
	_characters.clear()
	if cutscene != null:
		for character in cutscene.characters:
			_characters[character.name] = character
	
	_current_script_page = -1

## Prepares this [DialogueCutscene] and child nodes for display, then reveals them.
## After nodes are fully revealed, begins to display the first page of the scene.
## Must have already set / initialized [member cutscene] data before calling.
func open_cutscene():
	if cutscene == null:
		push_error("Attempted to call open_cutscene without setting cutscene data"
			+ " first. Cannot open, emitting cutscene_finished event instead")
		cutscene_finished.emit()
		return

	_is_closing = false
	visible = true
	modulate = Color.TRANSPARENT
	_change_displayed_character(cutscene.dialogue_script[0].get_slice("|", 0))
	_dialogue_units = _parse_script_page(cutscene.dialogue_script[0])
	_on_starting_dialogue_unit(0, false)
	dialogue_display.reset()
	
	var fade_in_tween = create_tween() 
	fade_in_tween.tween_property(self, "modulate", Color.WHITE, FADE_DURATION)
	fade_in_tween.tween_callback(_attempt_scene_advance)

## Hides this [DialogueCutscene] and child nodes, then emits the [signal cutscene_finished] signal to indicate the scene is complete.
func close_cutscene():
	_is_closing = true
	visible = true
	modulate = Color.WHITE
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(self, "modulate", Color.TRANSPARENT, FADE_DURATION) 
	fade_out_tween.tween_property(self, "visible", false, 0) 
	fade_out_tween.tween_callback(emit_signal.bind("cutscene_finished"))

# =============== #
# Private Methods #
# =============== #
func _animate_talking(animation_name : String, speed : float) -> void:
	$Characters/Portrait/AnimatedMouth.play(animation_name, speed)

# Can only advance the scene if the cutscene has content available and all relevant children are ready.
# The idea is that attempting to advance the dialogue serves as a status check and (if necessary) an
# instruction to advance the scene.
func _attempt_scene_advance() -> void:
	var can_start_next_page : bool = \
		cutscene != null \
		and !_is_closing \
		and dialogue_display.attempt_dialogue_advance()
	
	if can_start_next_page:
		_current_script_page += 1
		if _current_script_page < cutscene.dialogue_script.size():
			_current_unit_i = -1
			_change_displayed_character(cutscene.dialogue_script[_current_script_page].get_slice("|", 0))
			_dialogue_units = _parse_script_page(cutscene.dialogue_script[_current_script_page])
			dialogue_display.display_dialogue(_dialogue_units)
		elif visible:
			close_cutscene()

# Changes expression, mouth graphic, name tag, and "talking" audio noise.
func _change_displayed_character(character_name : String) -> void:
	$DialogueContainer/NameTag/MarginContainer/CharacterName.text = character_name
	character_portrait.sprite_frames = _characters[character_name].expressions
	character_portrait.offset.y = -1 * character_portrait.sprite_frames.get_frame_texture("default", 0).get_height()
	character_mouth.sprite_frames = _characters[character_name].mouth_frames
	character_mouth.offset.y = -1 * character_mouth.sprite_frames.get_frame_texture("default", 0).get_height()
	
	if audio_stream_randomizer.streams_count > 0:
		audio_stream_randomizer.remove_stream(0)
	audio_stream_randomizer.add_stream(0, _characters[character_name].voice, 1)

# Private method responsible for translating [member DialogueCutsceneData.dialogue_script] pages into arrays of [DialogueUnit]
# Implements spec defined and documented in [DialogueUnit] to parse dialogue text and metadata.
func _parse_script_page(text : String) -> Array[DialogueUnit]:
	var units : Array[DialogueUnit] = []
	var meta_and_text : PackedStringArray = text.split("|", false)
	for i in range(1, meta_and_text.size(), 2):
		var regex = RegEx.new()
		regex.compile("[^.!?,]*[.!?,]+")
		var sentences = regex.search_all(meta_and_text[i + 1])
		var starting_point = 0
		var sentence_i = 0
		while starting_point < meta_and_text[i + 1].length() - 1:
			var end_index = sentences[sentence_i].get_end() if sentences.size() != sentence_i else meta_and_text[i + 1].length()
			var unit = DialogueUnit.new(meta_and_text[i + 1].substr(starting_point, end_index - starting_point), meta_and_text[i])
			if starting_point > 0:
				unit.delay_before = 0
			var last_char =  meta_and_text[i + 1].substr(end_index - 1, 1)
			if ",.!?".contains(last_char):
				if end_index >= meta_and_text[i + 1].length() - 1:
					unit.delay_after = max(END_OF_SENTENCE_PAUSE, unit.delay_after)
				else:
					unit.delay_after = END_OF_SENTENCE_PAUSE
			units.append(unit)
			starting_point = end_index
			sentence_i += 1
	return units

# ============== #
# Event Handling #
# ============== #
func _on_text_revealed():
	$AudioStreamPlayer.play()

func _on_starting_dialogue_unit(starting_unit_i : int, is_talking : bool) -> void:
	_current_unit_i = starting_unit_i
	$Characters/Portrait.play(_dialogue_units[_current_unit_i].expression_name)
	_on_is_talking_changed(is_talking)

func _on_is_talking_changed(is_talking : bool) -> void:
	if !is_talking:
		_animate_talking(_dialogue_units[_current_unit_i].resting_animation, _dialogue_units[_current_unit_i].speed_mult)
	else:
		_animate_talking(_dialogue_units[_current_unit_i].talking_animation, _dialogue_units[_current_unit_i].speed_mult)
