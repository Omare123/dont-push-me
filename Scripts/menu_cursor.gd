extends TextureRect

@export var  menu_parent_path: NodePath
@export var  cursor_offset: Vector2

@onready var menu_parent := get_node(menu_parent_path)
@onready var walk = $walk

var cursor_index : int = 0

	
func _process(_delta):
	var input = Vector2.ZERO
	if Input.is_action_just_pressed("up"):
		walk.play()
		input.y -= 1
	elif Input.is_action_just_pressed("down"):
		walk.play()
		input.y += 1
		
	if menu_parent is VBoxContainer:
		set_curson_from_index(cursor_index + input.y)
	#elif menu_parent is HBoxContainer:
		#set_curson_from_index(cursor_index + input.x)
	#elif menu_parent is GridContainer:
		#set_curson_from_index(cursor_index + input.x + input.y * menu_parent.columns)
		
	if Input.is_action_just_pressed("ui_select"):
		var current_menu_item := get_menu_item_at_index(cursor_index)
		if current_menu_item != null:
			if current_menu_item.has_method("cursor_select"):
				current_menu_item.cursor_select()

func get_menu_item_at_index(index: int) -> Control:
	if menu_parent == null:
		return null
	
	if index >= menu_parent.get_child_count() || index < 0:
		return null
		
	return menu_parent.get_child(index) as Control

func set_curson_from_index(index: int) -> void:
	var menu_item := get_menu_item_at_index(index)
	
	if menu_item == null:
		return
		
	var menu_item_position = menu_item.global_position
	var menu_item_size = menu_item.size
	
	global_position = Vector2(menu_item_position.x, menu_item_position.y + menu_item_size.y / 2) - (size / 2) - cursor_offset
	cursor_index = index


func _on_play_cursor_selected():
	MainTransition.change_scene("res://Scenes/level_7.tscn", 1)

func _on_instructions_cursor_selected():
	pass

func _on_exit_cursor_selected():
	get_tree().quit()
