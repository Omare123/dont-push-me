class_name Cat
extends CharacterBody2D

@export var tile_map: TileMap
@onready var sprite = $Sprite
@onready var ray_cast_2d = $RayCast2D
@onready var area_2d = $Area2D
@onready var next_step_indicator = $next_step_indicator
@onready var animation_tree = $AnimationTree


const HORIZONTAL = "H"
const VERTICAL = "V"
const FRONT = "F"
const SIDE = "S"
@export_enum(HORIZONTAL, VERTICAL) var orientation: String = HORIZONTAL
@export var attack_orientation: Vector2 = Vector2(0, 1)
@export var change_attack_orientation: bool = false

var facing_direction = Vector2i(0, -1)
var colliding = false
var last_position: Vector2i
var next_position: Vector2i
var moving: bool = false
var ray_cast_length = 9
func _ready():
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	if current_tile == null:
		return
		
	match orientation:
		HORIZONTAL:
			facing_direction = Vector2i(1, 0)
		VERTICAL:
			facing_direction = Vector2i(0, -1)
			
	next_position = get_target_tile(current_tile)
	move_next_step_indicator()
	
func _physics_process(delta):
	if moving:
		return
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		if collider is Player:
			collider.move(attack_orientation, true)
			set_animation_conditions("parameters/conditions/attacking")
func move():
	if moving:
		return
		
	moving = true
	update_blend_directions()
	set_animation_conditions("parameters/conditions/walking")
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var step = tile_map.map_to_local(next_position)
	var tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", global_position - Vector2(0, 1), 0.1)
	await tween.tween_property(self, "global_position", step, 0.1).finished
	next_position = get_target_tile(next_position)
	move_next_step_indicator()
	last_position = current_tile
	moving = false
	Game.check_allow_to_move()

func is_tile_walkable(tile_data: TileData):
	var slippery
	if Game.level > 3:
		tile_data.get_custom_data("slippery")
	if (tile_data == null || tile_data.get_custom_data("walkable") == false || tile_data.get_custom_data("walkable") == null) || slippery != null:
		return false
	return true

func is_dead_zone(tile_data: TileData):
	return tile_data != null && tile_data.get_custom_data("dead_zone")

func get_target_tile(current_tile: Vector2i):
	var repeat = 0
	var posible_target_tile: Vector2i
	while repeat < 2:
		posible_target_tile = Vector2i(
			current_tile.x + facing_direction.x,
			current_tile.y + facing_direction.y 
		)
		update_blend_directions()
		var tile_data: TileData = tile_map.get_cell_tile_data(1, posible_target_tile)
		ray_cast_2d.target_position = facing_direction * ray_cast_length
		ray_cast_2d.force_raycast_update()
		if not is_tile_walkable(tile_data) || is_dead_zone(tile_data):
			facing_direction = facing_direction * -1
			if change_attack_orientation:
				attack_orientation = attack_orientation * -1
			repeat += 1
			continue
			
		if ray_cast_2d.is_colliding():
			var collider = ray_cast_2d.get_collider()
			var collider_parent = collider.get_parent()
			if collider is Player || collider is Next_Step || collider_parent is Player:
				return posible_target_tile
			if collider is Cat and collider.orientation != orientation:
				return posible_target_tile
			facing_direction = facing_direction * -1
			repeat += 1
			continue
		return posible_target_tile
	return posible_target_tile

func _on_cup_moving():
	move()

func move_next_step_indicator():
	var indicator_tween := next_step_indicator.create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await indicator_tween.tween_property(next_step_indicator, "global_position", tile_map.map_to_local(next_position), 0.2).finished

func set_animation_conditions(condition):
	animation_tree["parameters/conditions/walking"] = false
	animation_tree["parameters/conditions/attacking"] = false
	animation_tree[condition] = true

func update_blend_directions():
	animation_tree["parameters/walk/blend_position"] = facing_direction
	animation_tree["parameters/attack/blend_position"] = facing_direction

func _on_animation_tree_animation_finished(anim_name):
	update_blend_directions()
	set_animation_conditions("parameters/conditions/walking")
