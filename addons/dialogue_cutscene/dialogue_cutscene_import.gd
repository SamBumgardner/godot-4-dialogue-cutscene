@tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func _get_importer_name():
	return "dialogue_cutscene_data_importer"

func _get_visible_name():
	return "Dialogue Cutscene"

func _get_import_order() -> int:
	return -1000

## If we don't override this it won't realize it's a valid 
## importer for the recognized_extensions defined below.
func _get_priority() -> float:
	return 1000.0

func _get_recognized_extensions():
	return ["dc"]

func _get_save_extension():
	return "tres"

func _get_resource_type():
	return "Resource"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index) -> String:
	var name = ""
	match preset_index:
		Presets.DEFAULT:
			name = "default"
		_:
			name = "unknown"
	return name

func _get_import_options(path, preset_index) -> Array:
	var import_options:Array

	match preset_index:
		Presets.DEFAULT:
			import_options = [
				{
					"name": "character_data_path",
					"default_value": "res://data/dialogue_cutscene/characters",
					"property_hint": PROPERTY_HINT_DIR,
					"hint_string": "Path to directory storing DialogueCharacter resources"
				}
			]

	return import_options

func _get_option_visibility(path, option_name, options) -> bool:
	return true

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	
	var parsed_cutscene = DialogueCutsceneData.new()
	
	var next_line : String = ""
	while file.get_position() < file.get_length() or next_line != "":
		if next_line == "":
			next_line = file.get_line()
		
		if next_line.substr(0,1) == "!":
			var new_section = next_line.get_slice("!", 1).strip_edges()
			match new_section:
				"characters":
					next_line = _parse_characters(file, options, parsed_cutscene)
				"script":
					next_line = _parse_script(file, options, parsed_cutscene)
				_:
					push_warning("dialogue_cutscene_import.gd - unrecognized !-delimited section: %s" % [new_section])
					next_line = ""
		else:
			next_line = ""

	return ResourceSaver.save(parsed_cutscene, "%s.%s" % [save_path, _get_save_extension()])

func _parse_characters(file, options, parsed_cutscene) -> String:
	var unprocessed_line : String

	while file.get_position() < file.get_length():
		unprocessed_line = file.get_line()
		if unprocessed_line.substr(0,1) == "!":
			break
		
		var character_name = unprocessed_line.strip_edges()
		var expected_filename = "%s/DialogueCharacter_%s.tres" % [options.character_data_path, character_name]
		if FileAccess.file_exists(expected_filename):
			var character_resource = load(expected_filename)
			parsed_cutscene.characters.append(character_resource)
		else:
			push_warning("dialogue_cutscene_import.gd - could not find file %s to load character resource" % [expected_filename])
	
	return unprocessed_line

func _parse_script(file, _options, parsed_cutscene) -> String:
	var unprocessed_line : String = ""
	var current_script_page : String = ""
	var full_script : Array[String] = []

	while file.get_position() < file.get_length():
		unprocessed_line = file.get_line()

		if current_script_page.is_empty():
			current_script_page = _get_next_speaker_name(unprocessed_line)
		else:
			var cleaned_line = unprocessed_line.strip_edges()
			current_script_page += cleaned_line
			if current_script_page.ends_with("|"): # end of current page
				full_script.append(current_script_page)
				current_script_page = ""
			elif current_script_page != "":
				current_script_page += "\n"

	parsed_cutscene.dialogue_script = PackedStringArray(full_script)

	return unprocessed_line

func _get_next_speaker_name(line_to_check) -> String:
	if line_to_check.contains(":"):
		return line_to_check.get_slice(":", 0).strip_edges()
	else:
		return ""
