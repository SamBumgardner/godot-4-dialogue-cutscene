class_name Dialogue
extends Label
## Emits events as text is incrementally displayed via the [member visible_characters] property
##   non_whitespace_char_revealed - emitted each frame that non-whitespace text is revealed.
##     Should be used to trigger behavior that happens repeatedly during text reveal, like playing sounds effects to represent speech.
##   is_talking_changed - [member _is_talking] tracks if any text was revealed during the last displayed frame. This is emitted when its value changes.
##     Should be used to activate / deactivate behavior that only plays during text reveal (like talking animations)

signal is_talking_changed
signal non_whitespace_char_revealed

var not_whitespace_regex : RegEx = RegEx.new()
var visible_characters_set : bool = false
var is_talking

func _ready():
	not_whitespace_regex.compile("\\S")

func _set(property, value):
	if(property == "visible_characters"):
		visible_characters_set = true
		if value != visible_characters:
			var revealed_characters = text.substr(visible_characters, value - visible_characters)
			if not_whitespace_regex.search(revealed_characters) != null:
				non_whitespace_char_revealed.emit()

func _process(_delta):
	if visible_characters_set and !is_talking:
		is_talking = true
		is_talking_changed.emit(is_talking)
	elif !visible_characters_set and is_talking:
		is_talking = false
		is_talking_changed.emit(is_talking)
	
	visible_characters_set = false
