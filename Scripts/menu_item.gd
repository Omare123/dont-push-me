extends Label

signal cursor_selected()

func cursor_select():
	print(name)
	emit_signal("cursor_selected")
