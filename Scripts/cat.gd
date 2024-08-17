extends CharacterBody2D
@onready var ray_cast_2d = $RayCast2D
var is_attaking = false

func _process(delta):
	#ray_cast_2d.target_position = direction * 16
	#ray_cast_2d.force_raycast_update()
	
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		if collider is Player:
			collider.move(get_attack_direction(), true)
		#this is where we shoul attack
		return

func get_attack_direction():
	var i = randi()
	if i % 2 == 0:
		return Vector2.RIGHT
	else:
		return Vector2.LEFT
