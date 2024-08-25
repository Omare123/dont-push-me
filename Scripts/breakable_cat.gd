class_name Breakable_Cat
extends CharacterBody2D

@export var flip: bool
@onready var sprite = $Sprite
@onready var area_2d = $Area2D
@onready var ray_cast_2d = $RayCast2D
@onready var attack = $attack
@onready var broken = $Broken

var tile_map: TileMap
var tween: Tween
var moving: bool = false
func _ready():
	tile_map = get_parent().get_child(0)
	if flip:
		sprite.flip_h = true
		broken.flip_h = true

func move(direction: Vector2):
	if moving:
		return
	moving = true
	if is_object_in_the_way(direction):
		moving = false
		return
		
	var current_tile: Vector2i = get_current_position()
	var target_tile: Vector2i = Vector2i(
		current_tile.x + direction.x,
		current_tile.y + direction.y
	)
	var tile_data: TileData = tile_map.get_cell_tile_data(1, target_tile)
	var is_tile_dead_zone: bool = is_dead_zone(tile_data)

	if (is_tile_dead_zone):
		target_tile = Vector2i(
		target_tile.x + direction.x,
		target_tile.y + direction.y
		)
		move_animation(target_tile, true)
		Game.allow_to_move = false
		return
	
	move_animation(target_tile)
	await tween.finished
	moving = false

func get_current_position():
	return tile_map.local_to_map(global_position)

func is_object_in_the_way(direction: Vector2):
	ray_cast_2d.target_position = direction * 16
	ray_cast_2d.force_raycast_update()
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		if collider is Breakable_Cat:
			return true
	return false

func is_dead_zone(tile_data: TileData):
	return tile_data != null && tile_data.get_custom_data("dead_zone")

func move_animation(target_tile: Vector2i, breaking: bool = false):
	tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", global_position - Vector2(0, 1), 0.05)
	tween.tween_property(sprite, "scale", sprite.scale + Vector2(0.1, 0.1), 0.05)
	tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile), 0.05)
	if breaking:
		attack.play()
	tween.tween_property(sprite, "scale", Vector2(1,1), 0.05)
	await tween.finished
	if breaking:
		sprite.visible = false
		broken.visible = true
