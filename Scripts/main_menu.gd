extends Control
@onready var menu_cursor = $menu_cursor
@onready var options = $PanelContainer/VBoxContainer
@onready var instructions = $PanelContainer/VBoxContainer2


func _on_instructions_cursor_selected():
	options.visible = false
	instructions.visible = true
	menu_cursor.menu_parent = instructions
	menu_cursor.set_curson_from_index(0)


func _on_back_cursor_selected():
	options.visible = true
	instructions.visible = false
	menu_cursor.menu_parent = options
	menu_cursor.set_curson_from_index(0)
