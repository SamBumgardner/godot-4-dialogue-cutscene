extends RefCounted

class_name DialogueUnit

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
