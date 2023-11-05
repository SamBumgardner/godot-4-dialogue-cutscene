extends Node2D

var cutscenes : Array[DialogueCutsceneData] = [
	preload("res://Dialogue/data/Cutscene_01.tres"),
	preload("res://Dialogue/data/Cutscene_02.tres"),
	preload("res://Dialogue/data/Cutscene_03.tres"),
]
var current_cutscene_i = 0

func _ready():
	_init_gameplay()
	$CutsceneLayer/DialogueCutscene.cutscene_finished.connect(_on_cutscene_finished)

func _init_gameplay() -> void:
	var gameplay_tween = create_tween()
	gameplay_tween.tween_property($GameplayLayer/MockGameplay, "position", Vector2(1000, 325), 3)
	gameplay_tween.tween_property($GameplayLayer/MockGameplay, "position", Vector2(150, 325), 3)
	gameplay_tween.set_loops(-1)

func _input(event) -> void:
	if event.is_action_pressed("ui_accept"):
		start_cutscene(cutscenes[current_cutscene_i])

func start_cutscene(cutscene : DialogueCutsceneData) -> void:
	get_tree().paused = true
	
	$CutsceneLayer.show()
	$CutsceneLayer/DialogueCutscene.init_cutscene(cutscene)
	$CutsceneLayer/DialogueCutscene.fade_in()

func _on_cutscene_finished() -> void:
	current_cutscene_i = (current_cutscene_i + 1) % cutscenes.size()
	get_tree().paused = false
	$CutsceneLayer.hide()
