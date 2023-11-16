class_name DialogueUnit
extends RefCounted
## Fundamental building block of a [DialogueCutsceneData] script.
## Contains text to display and metadata to explain how it should be presented.
##
## See [method _init] for details of metadata parsing.

const DEFAULT_SPEED_MULTIPLIER = 1

var text : String
var speed_mult : float = DEFAULT_SPEED_MULTIPLIER
var delay_before : float = 0
var delay_after : float = 0
var expression_name = "default"
var talking_animation : String = "talking"
var resting_animation : String = "default"

## Constructor
## Responsible for parsing comma-separated metadata.
##
## Metadata is provided as a comma-separated string of raw values. The order they're
## provided in indicates what value they represent. 
##
## Values are optional, but cannot be skipped - if metadata needs to include resting_animation, 
## it'll need to also set values for speed_mult, delay_before, delay_after, expression_name, and talking_animation
##
## An example metadata string:
##   "1,.5,2,happy,talking,laughing"
## Would lead to the creation of a [DialogueUnit] containing the following data:
##   speed_mult = 1
##   delay_before = .5
##   delay_after = 2.0
##   expression_name = "happy"
##   talking_animation = "talking"
##   resting_animation = "laughing"
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
			3: expression_name = raw_data
			4: talking_animation = raw_data
			5: resting_animation = raw_data
