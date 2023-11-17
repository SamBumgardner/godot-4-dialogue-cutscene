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
	return ResourceSaver.save(DialogueCutsceneData.new(), "%s.%s" % [save_path, _get_save_extension()])
