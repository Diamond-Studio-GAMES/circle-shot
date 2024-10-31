class_name Menu
extends Control

var _name_accepted := false

func _ready() -> void:
	($About as Window).title = "Об игре (версия: %s)" % Globals.version
	if Globals.get_string("player_name").is_empty():
		($NameDialog as Window).popup_centered()


func _on_name_dialog_visibility_changed() -> void:
	if not ($NameDialog as Window).visible and not _name_accepted:
		($NameDialog as Window).popup_centered.call_deferred()


func _on_play_network_pressed() -> void:
	Globals.main.open_local_game()


func _on_settings_pressed() -> void:
	Globals.main.open_settings()


func _on_name_dialog_name_accepted() -> void:
	_name_accepted = true
