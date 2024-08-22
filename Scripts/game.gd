extends Node2D
@onready var game = $"."
var level: int = 1 
const LEVELS_PATH = "res://Scenes/level_%s.tscn"
var player: Player
var allow_to_move: bool = false
var levels_cats: Array[Cat] = []

func _ready():
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func next_level():
	level += 1 
	levels_cats = []
	var path: String = LEVELS_PATH % level
	get_tree().change_scene_to_file(path)

func set_player(new_player: Player):
	player = new_player
	
func fill_cat_array():
	var level = get_tree().root.get_child(2).get_children()
	for node in level:
		if node is Cat:
			levels_cats.append(node)
	allow_to_move = true

func check_allow_to_move():
	allow_to_move = !levels_cats.any(cat_is_moving)
	
func cat_is_moving(cat: Cat):
	return cat.moving
