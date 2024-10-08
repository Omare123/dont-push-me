extends Node2D
@onready var game = $"."
var level: int = 1
const LEVELS_PATH = "res://Scenes/level_%s.tscn"
const FIRST_LEVEL = "res://Scenes/level_1.tscn"
var player: Player
var allow_to_move: bool = false
var levels_cats: Array[Cat] = []
var changing_level = false

func next_level(final: bool = false):
	if changing_level:
		return
	changing_level = true
	level += 1 
	levels_cats = []
	var path: String = LEVELS_PATH % level
	if final:
		path = "res://Scenes/final.tscn"
	MainTransition.change_scene(path, level, final)
	#get_tree().change_scene_to_file(path)

func set_player(new_player: Player):
	player = new_player
	
func fill_cat_array():
	var level_node = get_tree().root.get_child(2).get_children()
	for node in level_node:
		if node is Cat and node != null:
			levels_cats.append(node)
	allow_to_move = true

func check_allow_to_move():
	if allow_to_move:
		return
	var can_move = true
	for cat in levels_cats:
		if cat == null:
			continue
		var cat_is_moving = cat.moving || (cat.tween and cat.tween.is_running())
		if cat_is_moving:
			can_move = false
			break
	allow_to_move = can_move
