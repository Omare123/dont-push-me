extends Label

signal cursor_selected()

func cursor_select():
	emit_signal("cursor_selected")
