class_name Game
extends Node

## Главный класс игровой части.
##
## Управляет сетью и переходами между состояниями игры. 

signal created
signal joined
signal closed
signal started
signal ended
enum FailReason {
	DIFFERENT_VERSION = 1,
	FULL_ROOM = 2,
	IN_GAME = 3,
}
const PORT: int = 7415
const LISTEN_PORT: int = 7414
const MAX_CLIENTS: int = 11 # Ещё один чтобы успешно отклонять.

## Максимальное число игроков, превысив которое, сервер начнёт отклонять соединения.
## Задаётся [Lobby] на основе выбранного события. Не имеет эффекта на клиентах.
var max_players: int = 10
var game: Game
var _scene_multiplayer: SceneMultiplayer
var _players_data := {}
var _players_not_ready: Array[int] = []
@onready var _loader: Loader = $Loader


func _ready() -> void:
	_scene_multiplayer = multiplayer
	_scene_multiplayer.auth_callback = _authenticate_callback


func _exit_tree() -> void:
	# Очистка на всякий случай
	if multiplayer.multiplayer_peer:
		close()


func init_connect_local_menu() -> void:
	var menu_scene: PackedScene = load("uid://wgln4clkkuuk")
	var menu: Control = menu_scene.instantiate()
	add_child(menu)
	print_verbose("Created connect_local_menu.")
	_init_lobby()


func create() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		show_error("Невозможно создать сервер! Ошибка: %s" % error_string(error))
		print_verbose("Can't create server with error: %s." % error_string(error))
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	created.emit()
	print_verbose("Created server at port %d." % PORT)


func join(ip: String) -> void:
	if not ip.is_valid_ip_address():
		show_error("Введён некорректный IP-адрес!")
		return
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip, PORT)
	if error != OK:
		show_error("Невозможно начать подключение! Ошибка: %s" % error_string(error))
		push_warning("Can't initiate connection with error: %s." % error_string(error))
		return
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		show_error("Невозможно начать подключение!")
		push_warning("Can't initiate connection.")
		return
	# Уменьшаем время тайм-аута
	for i: ENetPacketPeer in peer.host.get_peers():
		i.set_timeout(1500, 3000, 6000)
	multiplayer.multiplayer_peer = peer
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	_scene_multiplayer.peer_authenticating.connect(_on_peer_authenticating)
	_scene_multiplayer.peer_authentication_failed.connect(_on_peer_authentication_failed)
	($ConnectingDialog as Window).show()
	($ConnectingDialog as AcceptDialog).dialog_text = "Подключение к %s..." % ip
	print_verbose("Connecting to %s..." % ip)


func close() -> void:
	if not multiplayer.multiplayer_peer:
		push_warning("Can't close because game is already closed!")
		return
	
	if (
			multiplayer.multiplayer_peer.get_connection_status() ==
			MultiplayerPeer.CONNECTION_CONNECTED
			and not 1 in _scene_multiplayer.get_authenticating_peers()
	):
		closed.emit()
	
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	if _scene_multiplayer.peer_authenticating.is_connected(_on_peer_authenticating):
		_scene_multiplayer.peer_authenticating.disconnect(_on_peer_authenticating)
	if _scene_multiplayer.peer_authentication_failed.is_connected(_on_peer_authentication_failed):
		_scene_multiplayer.peer_authentication_failed.disconnect(_on_peer_authentication_failed)
	
	multiplayer.multiplayer_peer.close()
	multiplayer.set_deferred(&"multiplayer_peer", null)
	print_verbose("Closed.")
	# Добавить игры очистку при закрытии


func load_event(event_id: int, map_id: int) -> void:
	if multiplayer.is_server():
		_players_not_ready = multiplayer.get_peers()
		_players_not_ready.append(1)
		_players_data.clear()
	_loader.load_event(event_id, map_id)
	var success: bool = await _loader.loaded
	if not success:
		close()
		started.emit()
		return
	closed.connect(_loader.finish_load, CONNECT_ONE_SHOT)
	if multiplayer.is_server():
		if Globals.HEADLESS:
			_players_not_ready.erase(1)
			_check_players_ready()
		else:
			_send_player_data(($Lobby as Lobby).get_player_data())
	else:
		_send_player_data.rpc_id(1, ($Lobby as Lobby).get_player_data())


func end_game() -> void:
	if is_instance_valid(game):
		game.queue_free()
		game = null
	ended.emit()


func show_error(error_text: String) -> void:
	($ErrorDialog as AcceptDialog).dialog_text = error_text
	($ErrorDialog as AcceptDialog).popup_centered()


@rpc("any_peer", "reliable")
func _send_player_data(data: Array) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if not id:
		id = 1
	_players_data[id] = data
	_players_not_ready.erase(id)
	_check_players_ready()


@rpc("call_local", "reliable")
func _start_game() -> void:
	started.emit()
	game = $Game as Game
	game.game_ended.connect(end_game)
	closed.disconnect(_loader.finish_load)
	if multiplayer.is_server():
		game.init_game(_players_data)
	else:
		game.init_game()
	_loader.finish_load()


func _check_players_ready() -> void:
	if not multiplayer.is_server():
		return
	if _players_not_ready.is_empty():
		_start_game.rpc()


func _init_lobby() -> void:
	var lobby_scene: PackedScene = load("uid://cmwb81du1kbtm")
	var lobby: Control = lobby_scene.instantiate()
	add_child(lobby)
	print_verbose("Created lobby.")


func _authenticate_callback(peer: int, data: PackedByteArray) -> void:
	if not peer in _scene_multiplayer.get_authenticating_peers():
		push_warning("Unexpected authenticating message! Peer: %d is not authenticating!" % peer)
		return
	
	if not multiplayer.is_server():
		if peer != 1:
			push_warning("Unexpected authenticating message! Peer: %d" % peer)
			return
		if data.is_empty():
			push_error("Invalid data received! Data is empty!")
			return
		match data[0]:
			OK:
				_scene_multiplayer.complete_auth(peer)
				return
			FailReason.DIFFERENT_VERSION:
				($ConnectingDialog as Window).hide()
				show_error("Невозможно подключиться к игре! Версия сервера (%s) не совпадает с вашей (%s)." % [
					Globals.version,
					data.slice(1).get_string_from_utf8(),
				])
				push_warning("Can't connect: different versions (%s - local and %s - server)." % [
					Globals.version,
					data.slice(1).get_string_from_utf8(),
				])
			FailReason.FULL_ROOM:
				($ConnectingDialog as Window).hide()
				show_error("Невозможно подключиться к игре! Игра уже заполнена.")
				push_warning("Can't connect: full room.")
			FailReason.IN_GAME:
				($ConnectingDialog as Window).hide()
				show_error("Невозможно подключиться к игре! Игра уже началась.")
				push_warning("Can't connect: game already started.")
			_:
				push_error("Invalid data received! Data is not AuthState!")
		close()
		return
	
	if data != Globals.version.to_utf8_buffer():
		_scene_multiplayer.send_auth(
				peer,
				PackedByteArray([FailReason.DIFFERENT_VERSION]) + Globals.version.to_utf8_buffer()
		)
		print_verbose("Rejecting %d: different version (%s - local, %s - client)." % [
			peer,
			Globals.version,
			data.get_string_from_utf8(),
		])
		return
	if multiplayer.get_peers().size() + int(not Globals.headless) + 1 >= max_players:
		_scene_multiplayer.send_auth(peer, PackedByteArray([FailReason.FULL_ROOM]))
		print_verbose("Rejecting %d: full room." % peer)
		return
	# In Game
	
	_scene_multiplayer.send_auth(peer, PackedByteArray([OK]))
	_scene_multiplayer.complete_auth(peer)
	print_verbose("Completing authentication for peer %d." % peer)


func _on_peer_authenticating(peer: int) -> void:
	if multiplayer.is_server():
		print_verbose("Authenticating peer: %d." % peer)
		return
	if peer != 1:
		push_warning("Unexpected authenticating message! Peer: %d" % peer)
		return
	
	var data: PackedByteArray = Globals.version.to_utf8_buffer()
	_scene_multiplayer.send_auth(peer, data)
	($ConnectingDialog as AcceptDialog).dialog_text = "Аутентификация..."
	print_verbose("Sending version... (%s)" % Globals.version)


func _on_peer_authentication_failed(peer: int) -> void:
	if multiplayer.is_server():
		print_verbose("Peer authentication failed: %d." % peer)
		return
	
	($ConnectingDialog as Window).hide()
	show_error("Невозможно аутентифицироваться!")
	push_warning("Authentication failed: %d." % peer)
	close()


func _on_connected_to_server() -> void:
	($ConnectingDialog as Window).hide()
	joined.emit()
	multiplayer.connection_failed.disconnect(_on_connection_failed)
	multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	print_verbose("Connected to server.")


func _on_connection_failed() -> void:
	($ConnectingDialog as Window).hide()
	show_error("Невозможно подключиться к серверу!")
	push_warning("Connection failed.")
	close()


func _on_peer_disconnected(id: int) -> void:
	if id in _players_not_ready:
		_players_not_ready.erase(id)
		_players_data.erase(id)
		_check_players_ready()
	print_verbose("Peer disconnected: %d." % id)


func _on_server_disconnected() -> void:
	show_error("Разорвано соединение с сервером!")
	push_warning("Disconnected from server.")
	# Излучаем сигнал сами, потому что мы уже отключены
	closed.emit()
	close()
