class_name Player
extends CharacterBody2D
@onready var tile_map = $"../Levels/Level 1"
@onready var sprite = $Sprite2D
@onready var ray_cast_2d = $RayCast2D

var last_check_point = Vector2i(5,1)
var is_moving = false

func _process(delta):
	if is_moving:
		return
		
	if Input.is_action_pressed("up"):
		move(Vector2.UP)
	elif Input.is_action_pressed("down"):
		move(Vector2.DOWN)
	elif Input.is_action_pressed("left"):
		move(Vector2.LEFT)
	elif Input.is_action_pressed("right"):
		move(Vector2.RIGHT)
		
func move(direction: Vector2, is_attack = false):
	if is_attack and is_moving:
		return
	
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y
	)
	var tile_data: TileData = tile_map.get_cell_tile_data(1, target_tile)
	var is_dead_zone: bool = is_dead_zone(tile_data)
	if not is_tile_walkable(tile_data) && !(is_dead_zone and is_attack):
		return
	
	ray_cast_2d.target_position = direction * 16
	ray_cast_2d.force_raycast_update()
	
	if ray_cast_2d.is_colliding():
		return
	is_moving = true
	
	if (is_dead_zone and is_attack):
		global_position = tile_map.map_to_local(last_check_point)
		sprite.global_position = tile_map.map_to_local(last_check_point)
		is_moving = false
		return
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", global_position - Vector2(0, 1), 0.1)
	tween.tween_property(sprite, "scale", sprite.scale + Vector2(0.1, 0.1), 0.1)
	tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile), 0.1)
	await tween.tween_property(sprite, "scale", sprite.scale, 0.1).finished
	is_moving = false

func is_tile_walkable(tile_data: TileData):
	if (tile_data == null || tile_data.get_custom_data("walkable") == false || tile_data.get_custom_data("walkable") == null):
		return false
	return true

func is_dead_zone(tile_data: TileData):
	return tile_data != null && tile_data.get_custom_data("dead_zone")
