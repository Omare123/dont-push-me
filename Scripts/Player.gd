class_name Player
extends CharacterBody2D
@export var tile_map: TileMap
@onready var sprite = $Sprite2D
@onready var enemies_ray_cast = $RayCast2D
@onready var objects_ray_cast = $ObjectsRayCast
@onready var walk = $sfx/walk
@onready var breaking = $sfx/breaking
@onready var area_2d = $Area2D
@onready var slip = $sfx/slip
@onready var clink = $sfx/clink
@onready var broken = $Broken
@onready var animation_player = $AnimationPlayer

signal moving
var next_position: Vector2i
var tween: Tween
var is_moving: bool = false
var final_scene = false

func _ready():
	Game.set_player(self)

func _physics_process(_delta):
	if !Game.allow_to_move and Game.level != 7:
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

func handle_attack(direction: Vector2):
	Game.allow_to_move = false
	var current_tile: Vector2i = get_current_position()
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y
	)
	var tile_data: TileData = tile_map.get_cell_tile_data(1, target_tile)
	var tile_in_the_middle_data: TileData = tile_map.get_cell_tile_data(1, target_tile - Vector2i(direction.x, direction.y))
	var is_tile_dead_zone: bool = is_dead_zone(tile_data) || is_dead_zone(tile_in_the_middle_data)
	next_position = target_tile
	if is_object_in_the_way(direction):
		return

	if (is_tile_dead_zone):
		target_tile = Vector2i(
		target_tile.x + direction.x,
		target_tile.y + direction.y
		)
		move_animation(target_tile, true)
		Game.allow_to_move = false
		breaking.play()
		return
	
	var slipped = is_slippery(tile_data)
	move_animation(target_tile)
	await tween.finished
	Game.allow_to_move = true
	if slipped:
		handle_slipper(direction, tile_data)
		get_parent().check_attack()
		return

func handle_slipper(direction: Vector2, tile_data: TileData):
	var slippery_value = tile_data.get_custom_data("slippery")
	var new_direction = slippery_direction(direction, slippery_value)
	slip.play()
	handle_attack(new_direction)
	
func move_animation(target_tile: Vector2i, breaking: bool = false):
	tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", global_position - Vector2(0, 1), 0.05)
	tween.tween_property(sprite, "scale", sprite.scale + Vector2(0.1, 0.1), 0.05)
	tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile), 0.05)
	walk.play()
	tween.tween_property(sprite, "scale", Vector2(1,1), 0.05)
	moving.emit()
	await tween.finished
	if breaking:
		sprite.visible = false
		broken.visible = true
	
func move_cancel_animation(target_tile: Vector2i, current_tile: Vector2i, direction: Vector2):
	var half_step = direction * (0.5)
	tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", global_position - Vector2(0, 1), 0.05)
	tween.tween_property(sprite, "scale", sprite.scale + Vector2(0.1, 0.1), 0.05)
	tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile) - half_step, 0.05)
	clink.play()
	tween.tween_property(sprite, "scale", Vector2(1,1), 0.05)
	tween.tween_property(self, "global_position", tile_map.map_to_local(current_tile), 0.05)
	moving.emit()
	await tween.finished
	
func attack(direction: Vector2):
	if is_moving:
		return
	is_moving = true
	var current_tile: Vector2i = get_current_position()
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y
	)
	next_position = target_tile
	var tile_data: TileData = tile_map.get_cell_tile_data(1, target_tile)
	var is_tile_dead_zone: bool = is_dead_zone(tile_data)
	if !is_tile_walkable(tile_data) || is_tile_dead_zone || is_breakable_cat_in_the_way(direction):
		next_position = current_tile
		move_cancel_animation(target_tile, current_tile, direction)
		is_moving = false
		return
	move_animation(target_tile)
	await tween.finished
	is_moving = false
func move(direction: Vector2):
	if Game.level == 7:
		attack(direction)
		return
	if !Game.allow_to_move || (tween and tween.is_running()):
		return
		
	Game.allow_to_move = false
	var current_tile: Vector2i = get_current_position()
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y
	)
	next_position = target_tile
	var tile_data: TileData = tile_map.get_cell_tile_data(1, target_tile)
	var is_tile_dead_zone: bool = is_dead_zone(tile_data)
	if !is_tile_walkable(tile_data) || is_tile_dead_zone || is_enemy_in_the_way(direction) || is_object_in_the_way(direction):
		next_position = current_tile
		move_cancel_animation(target_tile, current_tile, direction)
		return
		
	var slipped = is_slippery(tile_data) and (direction.x == 0 || direction.y == 0)
	move_animation(target_tile)
	moving.emit()
	await tween.finished
	
	if slipped:
		handle_slipper(direction, tile_data)
		get_parent().check_attack()
		return

func slippery_direction(direction: Vector2, slippery_value: int):
	if direction.x == 0:
		return Vector2(slippery_value, direction.y)
	
	if direction.y == 0:
		return Vector2(direction.x, slippery_value)
	
	return direction
	
func is_enemy_in_the_way(direction: Vector2):
	enemies_ray_cast.target_position = direction * 32
	enemies_ray_cast.force_raycast_update()
	if enemies_ray_cast.is_colliding():
		var collider = enemies_ray_cast.get_collider()
		if collider is Cat:
			if ((collider.facing_direction * -1) == Vector2i(direction)):
				return true
	return false

func get_current_position():
	return tile_map.local_to_map(global_position)

func is_object_in_the_way(direction: Vector2):
	objects_ray_cast.target_position = direction * 16
	objects_ray_cast.force_raycast_update()
	if objects_ray_cast.is_colliding():
		var collider = objects_ray_cast.get_collider()
		if collider is Cat:
			return false
		return true
	return false

func is_breakable_cat_in_the_way(direction: Vector2):
	objects_ray_cast.target_position = direction * 16
	objects_ray_cast.force_raycast_update()
	if objects_ray_cast.is_colliding():
		var collider = objects_ray_cast.get_collider()
		if collider is Breakable_Cat:
			collider.move(direction)
			return true
		return true
	return false

func _on_win_area_body_entered(body):
	if Game.level == 7:
		final_animation()
		return
	if body == self:
		Game.next_level()

func final_animation():
	final_scene = true
	animation_player.play("final_animation")
	return

func _on_breaking_finished():
	if !final_scene:
		get_tree().reload_current_scene()
	else:
		Game.next_level(true)
