class_name Player
extends CharacterBody2D
@export var tile_map: TileMap
@onready var sprite = $Sprite2D
@onready var enemies_ray_cast = $RayCast2D
@onready var objects_ray_cast = $ObjectsRayCast
@onready var walk = $sfx/walk
@onready var breaking = $sfx/breaking

signal moving
var last_check_point = Vector2i(5,1)
var is_moving = false

func _process(_delta):
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

func is_tile_walkable(tile_data: TileData):
	if (tile_data == null || tile_data.get_custom_data("walkable") == false || tile_data.get_custom_data("walkable") == null):
		return false
	return true

func is_dead_zone(tile_data: TileData):
	return tile_data != null && tile_data.get_custom_data("dead_zone")

func move(direction: Vector2, is_attack = false):
	if is_moving:
		return
	moving.emit()
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y
	)
	var tile_data: TileData = tile_map.get_cell_tile_data(1, target_tile)
	var is_dead_zone: bool = is_dead_zone(tile_data)
	if not is_tile_walkable(tile_data) && !(is_dead_zone and is_attack):
		return
	
	if is_enemy_in_the_way(direction) || is_object_in_the_way(direction):
		return
	is_moving = true
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	if (is_dead_zone and is_attack):
		tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile), 0.1)
		breaking.play()
		return
		
	tween.tween_property(self, "global_position", global_position - Vector2(0, 1), 0.1)
	tween.tween_property(sprite, "scale", sprite.scale + Vector2(0.1, 0.1), 0.1)
	tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile), 0.1)
	walk.play()
	await tween.tween_property(sprite, "scale", sprite.scale, 0.1).finished
	global_position = tile_map.map_to_local(target_tile)
	is_moving = false

func is_enemy_in_the_way(direction: Vector2):
	enemies_ray_cast.target_position = direction * 32
	enemies_ray_cast.force_raycast_update()
	if enemies_ray_cast.is_colliding():
		var collider = enemies_ray_cast.get_collider()
		if collider is Cat:
			if ((collider.facing_direction * -1) == Vector2i(direction)):
				return true
	return false

func is_object_in_the_way(direction: Vector2):
	objects_ray_cast.target_position = direction * 16
	objects_ray_cast.force_raycast_update()
	if objects_ray_cast.is_colliding():
		var collider = objects_ray_cast.get_collider()
		if collider is Cat:
			return false
		return true
	return false

func _on_win_area_body_entered(body):
	if body == self:
		Game.next_level()


func _on_breaking_finished():
	get_tree().reload_current_scene()
