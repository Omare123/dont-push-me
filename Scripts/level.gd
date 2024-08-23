class_name Level extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	Game.fill_cat_array()

func check_attack(calling_cat: Cat):
	for cat in Game.levels_cats:
		if cat == null || cat == calling_cat:
			continue
		cat.check_attack()
	Game.allow_to_move = true
