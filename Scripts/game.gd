extends Node2D
@onready var game = $"."
var level: int = 1 
const LEVELS_PATH = "res://Scenes/level_%s.tscn"

func _ready():
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func next_level():
	level += 1 
	var path: String = LEVELS_PATH % level
	get_tree().change_scene_to_file(path)
