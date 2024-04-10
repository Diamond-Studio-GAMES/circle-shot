class_name Menu
extends Control


signal game_create_requested
signal game_join_requested(ip: String)
signal game_start_requested()
var _players := {}
var _player_admin_id := -1
@onready var _ip_dialog: ConfirmationDialog = $IPDialog
@onready var _ip_edit: LineEdit = $IPDialog/LineEdit 
@onready var _players_container: VBoxContainer = $Base/Centering/Lobby/Panel/Players
@onready var _error_dialog: AcceptDialog = $ErrorDialog


func _ready() -> void:
	_ip_dialog.register_text_enter($IPDialog/LineEdit as LineEdit)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if Shooter.HEADLESS:
		print("Creating server on headless...")
		_on_create_pressed.call_deferred()


@rpc
func add_player_entry(id: int, player_name: String) -> void:
	var label := Label.new()
	label.text = player_name
	label.name = str(id)
	if id == multiplayer.get_unique_id() or id == 1 and not Shooter.HEADLESS:
		label.text += " (Ты)"
	_players_container.add_child(label)


@rpc
func delete_player_entry(id: int) -> void:
	_players_container.get_node(str(id)).queue_free()


@rpc("any_peer")
func register_new_player(player_name: String, data := {}) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	for i: int in _players:
		add_player_entry.rpc_id(id, i, _players[i])
	_players[id] = player_name
	if _players.size() == 1:
		_player_admin_id = id
		if Shooter.HEADLESS:
			set_admin.rpc_id(id, true)
		else:
			set_admin(true)
	else:
		set_admin.rpc_id(id, false)
	add_player_entry.rpc(id, player_name)
	if not Shooter.HEADLESS:
		add_player_entry(id, player_name)


@rpc
func set_admin(admin: bool) -> void:
	($Base/Centering/Lobby/StartGame as Button).visible = admin
	($Base/Centering/Lobby/Hint as Label).visible = not admin


@rpc
func request_start_game() -> void:
	if multiplayer.get_remote_sender_id() != _player_admin_id:
		return
		


func create_error_dialog(text: String, code := -1) -> void:
	_error_dialog.dialog_text = text
	if code > 0:
		text += " Код ошибки: %d" % code
	_error_dialog.popup_centered()


func _on_create_pressed() -> void:
	game_create_requested.emit()


func _on_join_pressed() -> void:
	_ip_dialog.popup_centered()
	_ip_edit.grab_focus()


func _on_ip_dialog_confirmed() -> void:
	if _ip_edit.text.is_valid_ip_address():
		game_join_requested.emit(_ip_edit.text)
		_ip_dialog.hide()
	else:
		_ip_edit.placeholder_text = "Некорректный IP-адрес!"
		_ip_edit.text = ""


func _on_line_edit_text_changed(_new_text: String) -> void:
	_ip_dialog.dialog_text = ""


func _on_game_created(error: int) -> void:
	if error:
		create_error_dialog("Невозможно создать сервер!", error)
		return
	($Base/Centering/Lobby as Control).show()
	($Base/Centering/Main as Control).hide()
	if not Shooter.HEADLESS:
		register_new_player(($Base/Centering/Main/Name/LineEdit as LineEdit).text)


func _on_game_joined(error: int) -> void:
	if error:
		create_error_dialog("Невозможно подключиться к серверу!", error)
		return
	($Base/Centering/Lobby as Control).show()
	($Base/Centering/Main as Control).hide()
	register_new_player.rpc_id(1, ($Base/Centering/Main/Name/LineEdit as LineEdit).text)


func _on_connection_closed() -> void:
	show()
	($Base/Centering/Lobby as Control).hide()
	($Base/Centering/Main as Control).show()


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	delete_player_entry.rpc(id)
	if not Shooter.HEADLESS:
		delete_player_entry(id)
