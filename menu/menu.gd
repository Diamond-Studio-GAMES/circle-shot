class_name Menu
extends Control


signal game_create_requested
signal game_join_requested(ip: String)
signal game_leave_requested
@warning_ignore("unused_signal")
signal game_start_requested()
var selected_game := 0
var selected_map := 0
var _players := {}
var _player_admin_id := -1
@onready var _ip_dialog: ConfirmationDialog = $IPDialog
@onready var _ip_edit: LineEdit = $IPDialog/LineEdit
@onready var _status: Label = $Base/Centering/Main/Status
@onready var _players_container: GridContainer = $Base/Centering/Lobby/Panel/Players
@onready var _error_dialog: AcceptDialog = $ErrorDialog


func _ready() -> void:
	_update_game_and_map()
	_ip_dialog.register_text_enter($IPDialog/LineEdit as LineEdit)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	if Global.HEADLESS:
		print("Creating server on headless...")
		_on_create_pressed.call_deferred()


@rpc("reliable")
func add_player_entry(id: int, player_name: String) -> void:
	var label := Label.new()
	label.text = player_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.name = str(id)
	if id == multiplayer.get_unique_id():
		label.text += " (Ты)"
	_players_container.add_child(label)


@rpc("reliable")
func delete_player_entry(id: int) -> void:
	_players_container.get_node(str(id)).queue_free()


@rpc("any_peer", "reliable")
func register_new_player(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	for i: int in _players:
		add_player_entry.rpc_id(id, i, _players[i])
	set_environment.rpc(selected_game, selected_map)
	_players[id] = player_name
	if _players.size() == 1:
		_player_admin_id = id
		if Global.HEADLESS:
			set_admin.rpc_id(id, true)
		else:
			set_admin(true)
	else:
		set_admin.rpc_id(id, false)
	add_player_entry.rpc(id, player_name)
	if not Global.HEADLESS:
		add_player_entry(id if id else 1, player_name)


@rpc("reliable")
func set_admin(admin: bool) -> void:
	($Base/Centering/Lobby/AdminPanel as VBoxContainer).visible = admin
	($Base/Centering/Lobby/ClientHint as Label).visible = not admin


@rpc("any_peer", "reliable")
func request_set_environment(game_id: int, map_id: int) -> void:
	if multiplayer.get_remote_sender_id() != _player_admin_id:
		return
	set_environment.rpc(game_id, map_id)


@rpc("call_local", "reliable")
func set_environment(game_id: int, map_id: int) -> void:
	selected_game = game_id
	selected_map = map_id
	_update_game_and_map()


@rpc("any_peer", "reliable")
func request_start_game() -> void:
	if multiplayer.get_remote_sender_id() != _player_admin_id:
		return
		


func create_error_dialog(text: String, code := -1) -> void:
	_error_dialog.dialog_text = text
	if code > 0:
		text += " Код ошибки: %d" % code
	_error_dialog.popup_centered()


func _update_game_and_map() -> void:
	var game: GameConfig = Global.items_db.games[selected_game]
	($Base/Centering/Lobby/Environment/Game as TextureRect).texture = load(game.image_path) as Texture2D
	($Base/Centering/Lobby/Environment/Game/Container/Name as Label).text = game.game_name
	($Base/Centering/Lobby/Environment/Game/Container/Description as Label).text = game.game_description
	
	($Base/Centering/Lobby/Environment/Map as TextureRect).texture = \
			load(game.maps[selected_map].image_path) as Texture2D
	($Base/Centering/Lobby/Environment/Map/Container/Name as Label).text = game.maps[selected_map].map_name
	($Base/Centering/Lobby/Environment/Map/Container/Description as Label).text = \
			game.maps[selected_map].map_description


func _on_create_pressed() -> void:
	_status.text = "Создание сервера..."
	game_create_requested.emit()


func _on_join_pressed() -> void:
	_ip_dialog.popup_centered()
	_ip_edit.grab_focus()


func _on_leave_pressed() -> void:
	game_leave_requested.emit()


func _on_ip_dialog_confirmed() -> void:
	if _ip_edit.text.is_valid_ip_address():
		_status.text = "Подключение к %s..." % _ip_edit.text
		game_join_requested.emit(_ip_edit.text)
		_ip_dialog.hide()
	else:
		_ip_edit.placeholder_text = "Некорректный IP-адрес!"
		_ip_edit.text = ""


func _on_line_edit_text_changed(_new_text: String) -> void:
	_ip_edit.placeholder_text = "XXX.XXX.XXX.XXX"


func _on_game_created(error: int) -> void:
	_status.text = ""
	if error:
		create_error_dialog("Невозможно создать сервер!", error)
		return
	($Base/Centering/Lobby as Control).show()
	($Base/Centering/Main as Control).hide()
	if not Global.HEADLESS:
		register_new_player(($Base/Centering/Main/Name/LineEdit as LineEdit).text)


func _on_game_joined(error: int) -> void:
	_status.text = ""
	if error:
		create_error_dialog("Невозможно подключиться к серверу!", error)
		return
	($Base/Centering/Lobby as Control).show()
	($Base/Centering/Main as Control).hide()
	register_new_player.rpc_id(1, ($Base/Centering/Main/Name/LineEdit as LineEdit).text)


func _on_connection_closed() -> void:
	show()
	for i: Node in _players_container.get_children():
		i.queue_free()
	($Base/Centering/Lobby as Control).hide()
	($Base/Centering/Main as Control).show()


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	_players.erase(id)
	if id == _player_admin_id:
		_player_admin_id = (_players.keys() as Array[int])[0]
		set_admin.rpc_id(_player_admin_id, true)
	delete_player_entry.rpc(id)
	if not Global.HEADLESS:
		delete_player_entry(id)


func _on_server_disconnected() -> void:
	create_error_dialog("Разорвано соединение с сервером!")


func _on_change_game_pressed() -> void:
	$ItemSelector.open_selection(ItemsDB.Item.GAME, selected_game)


func _on_change_map_pressed() -> void:
	$ItemSelector.open_selection(ItemsDB.Item.MAP, selected_map, selected_game)


func _on_item_selected(type: ItemsDB.Item, id: int) -> void:
	match type:
		ItemsDB.Item.GAME:
			if not multiplayer.is_server():
				request_set_environment.rpc_id(1, id, 0)
			else:
				request_set_environment(id, 0)
		ItemsDB.Item.MAP:
			if not multiplayer.is_server():
				request_set_environment.rpc_id(1, selected_game, id)
			else:
				request_set_environment(selected_game, id)
