extends Label

class_name Dialogue

signal text_revealed

var not_whitespace_regex : RegEx = RegEx.new()

func _ready():
	not_whitespace_regex.compile("\\S")

func _set(property, value):
	if(property == "visible_characters"):
		if value != visible_characters:
			var revealed_characters = text.substr(visible_characters, value - visible_characters)
			if not_whitespace_regex.search(revealed_characters) != null:
				text_revealed.emit()
