class_name Lobby
extends Control


signal game_created
signal game_joined(ip: String)
signal game_started()
@onready var _ip_dialog: ConfirmationDialog = $IPDialog
@onready var _ip_edit: LineEdit = $IPDialog/LineEdit 
@onready var _players: VBoxContainer = $Base/Centering/Lobby/Panel/Players



func _ready() -> void:
	_ip_dialog.register_text_enter($IPDialog/LineEdit as LineEdit)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


@rpc
func add_player_entry(player_name: String):
	var label := Label.new()
	label.text = player_name
	label.name = str(multiplayer.get_remote_sender_id())
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		label.name += " (Ты)"
	_players.add_child(label)


func _on_connected_to_server():
	$Base/Centering/Lobby.show()
	$Base/Centering/Main.show()
	add_player_entry.rpc(($Base/Centering/Main/Name/LineEdit as LineEdit).text)


func _on_create_pressed() -> void:
	game_created.emit()


func _on_join_pressed() -> void:
	_ip_dialog.popup_centered()


func _on_ip_dialog_confirmed() -> void:
	if _ip_edit.text.is_valid_ip_address():
		game_joined.emit(_ip_edit.text)
		_ip_dialog.hide()
	else:
		_ip_edit.placeholder_text = "Некорректный IP-адрес!"
		_ip_edit.text = ""


func _on_line_edit_text_changed(_new_text: String) -> void:
	_ip_dialog.dialog_text = ""
