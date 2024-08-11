class_name Menu
extends Control

var _name_accepted := false

func _ready() -> void:
	if Globals.get_string("player_name").is_empty():
		($NameDialog as AcceptDialog).register_text_enter($NameDialog/LineEdit as LineEdit)
		($NameDialog as Window).popup_centered()


func _on_play_online_pressed() -> void:
	Globals.main.open_local_game()


func _on_name_dialog_visibility_changed() -> void:
	if not ($NameDialog as Window).visible and not _name_accepted:
		($NameDialog as Window).popup_centered.call_deferred()


func _on_name_dialog_confirmed() -> void:
	var player_name: String = ($NameDialog/LineEdit as LineEdit).text.strip_edges().strip_escapes()
	if player_name.is_empty():
		($NameDialog/LineEdit as LineEdit).placeholder_text = "Недопустимое имя!"
		($NameDialog/LineEdit as LineEdit).clear()
		return
	_name_accepted = true
	Globals.set_string("player_name", player_name)
	($NameDialog as Window).hide()
	print_verbose("Name set: %s." % player_name)
