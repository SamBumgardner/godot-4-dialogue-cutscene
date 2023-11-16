class_name DialogueCutsceneData
extends Resource

## Set of [DialogueCharacter] used in this scene.
## Ordering doesn't matter, this should generally be used to create a dictionary keyed by character name.
## Godot's default editor makes adding custom resources to a dictionary a huge pain, though, so this is much simpler.
## Because of this, avoid adding the same character twice, or creating two characters with the same name.
@export var characters : Array[DialogueCharacter] = []

## Array of strings representing the "pages" of the cutscene's script.
## Each string should be constructed according to the specifications in [DialogueUnit].
## The combination of metadata and text provided here dictates the pacing and content of the scene.
@export var dialogue_script : PackedStringArray = PackedStringArray()
