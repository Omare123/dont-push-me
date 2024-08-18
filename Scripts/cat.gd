class_name Cat
extends CharacterBody2D

@export var tile_map: TileMap
@onready var sprite = $Sprite
@onready var ray_cast_2d = $RayCast2D


const HORIZONTAL = "H"
const VERTICAL = "V"
@export_enum(HORIZONTAL, VERTICAL) var orientation: String = HORIZONTAL

var is_moving = false
var facing_direction = Vector2i(0, -1)

func _ready():
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	if current_tile == null:
		return
		
	match orientation:
		HORIZONTAL:
			facing_direction = Vector2i(1, 0)
		VERTICAL:
			facing_direction = Vector2i(0, -1)
			
	get_target_tile(current_tile)

func _process(_delta):
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		if collider is Player:
			collider.move(get_attack_direction(), true)

func move():
	if is_moving:
		return
		
	is_moving = true
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var target_tile = get_target_tile(current_tile)
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", global_position - Vector2(0, 1), 0.1)
	await tween.tween_property(self, "global_position", tile_map.map_to_local(target_tile), 0.1).finished
	global_position = tile_map.map_to_local(target_tile)
	is_moving = false

func is_tile_walkable(tile_data: TileData):
	if (tile_data == null || tile_data.get_custom_data("walkable") == false || tile_data.get_custom_data("walkable") == null):
		return false
	return true

func is_dead_zone(tile_data: TileData):
	return tile_data != null && tile_data.get_custom_data("dead_zone")

func get_attack_direction():
	randomize()
	var i = randi()
	if i % 2 == 0:
		return Vector2.RIGHT
	else:
		return Vector2.LEFT

func get_target_tile(current_tile: Vector2i):
	var repeat = true
	while repeat:
		var posible_target_tile: Vector2i = Vector2i(
			current_tile.x + facing_direction.x,
			current_tile.y + facing_direction.y
		)
		var tile_data: TileData = tile_map.get_cell_tile_data(1, posible_target_tile)
		ray_cast_2d.target_position = facing_direction * 16
		ray_cast_2d.force_raycast_update()
		
		if ray_cast_2d.is_colliding():
			var collider = ray_cast_2d.get_collider()
			if collider is Player:
				return posible_target_tile
			if collider is Cat and collider.orientation != orientation:
				return posible_target_tile
			
		if ray_cast_2d.is_colliding() || not is_tile_walkable(tile_data) || is_dead_zone(tile_data):
			facing_direction = facing_direction * -1
			continue
		return posible_target_tile

func _on_cup_moving():
	move()
