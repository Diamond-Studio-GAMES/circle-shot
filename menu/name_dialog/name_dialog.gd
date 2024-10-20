extends AcceptDialog

signal name_accepted

func _ready() -> void:
	register_text_enter($LineEdit as LineEdit)


func _on_confirmed() -> void:
	var player_name: String = ($LineEdit as LineEdit).text.strip_edges().strip_escapes()
	($LineEdit as LineEdit).clear()
	if player_name.is_empty():
		($LineEdit as LineEdit).placeholder_text = "Недопустимое имя!"
		return
	Globals.set_string("player_name", player_name)
	hide()
	name_accepted.emit()
	print_verbose("Name set: %s." % player_name)
