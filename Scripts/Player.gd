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
var tween: Tween
func _ready():
	Game.set_player(self)

func _physics_process(delta):
	if !Game.allow_to_move:
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
	
func is_slippery(tile_data: TileData):
	if Game.level > 3:
		return tile_data != null && tile_data.get_custom_data("slippery")
	else:
		return false
		
func move(direction: Vector2, is_attack = false):
	if !Game.allow_to_move || (tween and tween.is_running()) and !is_attack:
		return
	Game.allow_to_move = false
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

	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	if (is_dead_zone and is_attack):
		tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile), 0.1)
		breaking.play()
		return
	var slipped = is_slippery(tile_data) and (direction.x == 0 || direction.y == 0)
	tween.tween_property(self, "global_position", global_position - Vector2(0, 1), 0.1)
	tween.tween_property(sprite, "scale", sprite.scale + Vector2(0.1, 0.1), 0.1)
	tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile), 0.1)
	walk.play()
	tween.tween_property(sprite, "scale", Vector2(1,1), 0.1)
	await tween.finished
	
	if slipped:
		var slippery_value = tile_data.get_custom_data("slippery")
		var new_direction = slippery_direction(direction, slippery_value)
		move(new_direction, true)
		return

func slippery_direction(direction: Vector2, slippery_value: int):
	if direction.x == 0:
		return Vector2(slippery_value, direction.y)
	
	if direction.y == 0:
		return Vector2(direction.x, slippery_value)
	
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
	
func _on_area_2d_area_entered(area):
	var node = area.get_parent()
	if node is Cat:
		node.next_position = node.last_position
		node.move()
 
func _on_win_area_body_entered(body):
	if body == self:
		Game.next_level()


func _on_breaking_finished():
	get_tree().reload_current_scene()
