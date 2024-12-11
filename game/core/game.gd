class_name Game
extends Node

## Главный класс игровой части.
##
## Управляет сетью и переходами между состояниями игры. 

## Издаётся, когда создаётся игра.
signal created
## Издаётся при успешном подключении к игре.
signal joined
## Издаётся при закрытии игры.
signal closed
## Издаётся при успешном старте игры.
signal started
## Издаётся при окончании игры.
signal ended
## Перечисление причин отклонения подключения.
enum FailReason {
	## Разные версии.
	DIFFERENT_VERSION = 1,
	## Полная комната.
	FULL_ROOM = 2,
	## Уже в игре.
	IN_GAME = 3,
}
## Перечисление состояний игры.
enum State {
	## Игра закрыта.
	CLOSED = 0,
	## Подключение.
	CONNECTING = 1,
	## Подключено, в лобби.
	LOBBY = 2,
	## Подключено, загрузка игры.
	LOADING = 3,
	## Подключено, находится в событии.
	EVENT = 4,
	## Одиночная игра.
	SOLO = 5,
}
## Порт для подключения по умолчанию.
const DEFAULT_PORT: int = 7415
## Базовое время, определяющее через сколько соединение должно быть прервано (в мс).
## За подробностями - [method ENetPacketPeer.set_timeout].
const BASE_TIMEOUT: int = 1500
## Порт, через который ищутся игры по локальной сети.
const LISTEN_PORT: int = 7414
## Максимальное число клиентов. Используется при создании сервера.
const MAX_CLIENTS: int = 11 # Ещё один чтобы успешно отклонять.
## Максимальная длина имени игрока.
const MAX_PLAYER_NAME_LENGTH: int = 24

## Максимальное число игроков, превысив которое, сервер начнёт отклонять соединения.
## Задаётся лобби на основе выбранного события. Не имеет эффекта на клиентах.
var max_players: int = 10
## Текущее состояние игры.
var state := State.CLOSED
## Ссылка на событие.
var event: Event

var _scene_multiplayer: SceneMultiplayer
var _players_names: Dictionary[int, String]
var _players_equip_data: Dictionary[int, Array]
var _players_not_ready: Array[int]
@onready var _loader: Loader = $Loader


func _ready() -> void:
	_scene_multiplayer = multiplayer
	_scene_multiplayer.auth_callback = _authenticate_callback


func _exit_tree() -> void:
	# Очистка на всякий случай
	if multiplayer.multiplayer_peer:
		close()


## Инициализирует меню подключения к локальной игре и лобби.
func init_connect_local() -> void:
	var menu_scene: PackedScene = load("uid://wgln4clkkuuk")
	var menu: Control = menu_scene.instantiate()
	add_child(menu)
	print_verbose("Created connect_local_menu.")
	_init_lobby()


## Создаёт сервер.
func create(port: int = DEFAULT_PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		show_error("Невозможно создать сервер! Ошибка: %s" % error_string(error))
		print_verbose("Can't create server with error: %s." % error_string(error))
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_scene_multiplayer.peer_authenticating.connect(_on_peer_authenticating)
	_scene_multiplayer.peer_authentication_failed.connect(_on_peer_authentication_failed)
	state = State.LOBBY
	created.emit()
	print_verbose("Created server at port %d." % port)


## Пытается подключиться к серверу по [param ip].
func join(ip: String, port: int = DEFAULT_PORT) -> void:
	if not ip.is_valid_ip_address():
		show_error("Введён некорректный IP-адрес!")
		return
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip, port)
	if error != OK:
		show_error("Невозможно начать подключение! Ошибка: %s" % error_string(error))
		push_warning("Can't initiate connection with error: %s." % error_string(error))
		return
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		show_error("Невозможно начать подключение!")
		push_warning("Can't initiate connection.")
		return
	# Уменьшаем время тайм-аута
	peer.get_peer(MultiplayerPeer.TARGET_PEER_SERVER).set_timeout(
			BASE_TIMEOUT, BASE_TIMEOUT * 2, BASE_TIMEOUT * 3)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	_scene_multiplayer.peer_authenticating.connect(_on_peer_authenticating)
	_scene_multiplayer.peer_authentication_failed.connect(_on_peer_authentication_failed)
	multiplayer.multiplayer_peer = peer
	state = State.CONNECTING
	($ConnectingDialog as Window).show()
	($ConnectingDialog as AcceptDialog).dialog_text = "Подключение к %s..." % ip
	print_verbose("Connecting to %s..." % ip)


## Закрывает игру.
func close() -> void:
	if state == State.CLOSED:
		push_error("Can't close because game is already closed!")
		return
	
	if (
			multiplayer.multiplayer_peer.get_connection_status()
			== MultiplayerPeer.CONNECTION_CONNECTED
			and not MultiplayerPeer.TARGET_PEER_SERVER
			in _scene_multiplayer.get_authenticating_peers()
	):
		closed.emit()
	
	if multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.disconnect(_on_peer_connected)
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
	if is_instance_valid(event):
		# Чтобы _process не вызывались
		event.process_mode = Node.PROCESS_MODE_DISABLED
		event.queue_free()
		print_verbose("Event deleted.")
	state = State.CLOSED


## Загружает событие по данным [param event_id] и [param map_id]. Если вызвано сервером без игрока,
## [param player_name] и [param equip_data] можно не указывать.
func load_event(event_id: int, map_id: int, player_name := "", equip_data: Array[int] = []) -> void:
	state = State.LOADING
	if multiplayer.is_server():
		# Конвертация xD
		_players_not_ready = Array(multiplayer.get_peers() as Array, TYPE_INT, StringName(), null)
		_players_not_ready.append(1)
		_players_equip_data.clear()
		_players_names.clear()
		($WaitPlayersTimer as Timer).start()
	event = await _loader.load_event(event_id, map_id)
	if not is_instance_valid(event):
		show_error("Ошибка при загрузке события! Отключаюсь.")
		push_error("Loading failed. Disconnecting.")
		close()
		return
	closed.connect(_loader.finish_load.bind(false), CONNECT_ONE_SHOT)
	if multiplayer.is_server() and Globals.headless:
		_players_not_ready.erase(MultiplayerPeer.TARGET_PEER_SERVER)
		_check_players_ready()
		return
	print_verbose("Sending data. Name: %s, equip data: %s." % [player_name, str(equip_data)])
	_send_player_data.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER, player_name, equip_data)


## Показывает диалог с ошибкой.
func show_error(error_text: String) -> void:
	($ErrorDialog as AcceptDialog).dialog_text = error_text
	($ErrorDialog as AcceptDialog).popup_centered()


## Проверяет имя игрока и исправляет при необходимости. Если [param id] равен 0, не печатает
## никаких предупреждений.
static func validate_player_name(player_name: String, id: int = 0) -> String:
	# Там, где якобы пусто, стоит пустой символ
	player_name = player_name.strip_edges().strip_escapes().lstrip('⁣')
	if player_name.is_empty():
		return "Игрок%d" % id if id != 0 else "Игрок"
	elif player_name.length() > MAX_PLAYER_NAME_LENGTH:
		if id != 0:
			push_warning("Client's %d player name length (%d) is more than allowed (%d)." % [
				id,
				player_name.length(),
				MAX_PLAYER_NAME_LENGTH,
			])
		return player_name.left(MAX_PLAYER_NAME_LENGTH)
	return player_name


@rpc("any_peer", "reliable", "call_local", 1)
func _send_player_data(player_name: String, equip_data: Array[int]) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client.")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	player_name = validate_player_name(player_name, sender_id)
	if equip_data.size() != 6:
		push_warning("Client %d has invalid equip data size: %d." % [
			sender_id,
			equip_data.size(),
		])
		equip_data = [0, 0, 0, 0, 0, 0]
	
	if equip_data[0] < 0 or equip_data[0] >= Globals.items_db.skins.size():
		push_warning("Client's %d skin has invalid ID: %d." % [sender_id, equip_data[0]])
		equip_data[0] = 0
	if equip_data[1] < 0 or equip_data[1] >= Globals.items_db.weapons_light.size():
		push_warning("Client's %d light weapon has invalid ID: %d." % [sender_id, equip_data[1]])
		equip_data[1] = 0
	if equip_data[2] < 0 or equip_data[2] >= Globals.items_db.weapons_heavy.size():
		push_warning("Client's %d heavy weapon has invalid ID: %d." % [sender_id, equip_data[2]])
		equip_data[2] = 0
	if equip_data[3] < 0 or equip_data[3] >= Globals.items_db.weapons_support.size():
		push_warning("Client's %d support weapon has invalid ID: %d." % [sender_id, equip_data[3]])
		equip_data[3] = 0
	if equip_data[4] < 0 or equip_data[4] >= Globals.items_db.weapons_melee.size():
		push_warning("Client's %d melee weapon has invalid ID: %d." % [sender_id, equip_data[4]])
		equip_data[4] = 0
	if equip_data[5] < 0 or equip_data[5] >= Globals.items_db.skills.size():
		push_warning("Client's %d skill has invalid ID: %d." % [sender_id, equip_data[5]])
		equip_data[5] = 0
	
	_players_names[sender_id] = player_name
	_players_equip_data[sender_id] = equip_data
	_players_not_ready.erase(sender_id)
	print_verbose("Player %d sent data. Name: %s, Equip data: %s." % [
		sender_id,
		player_name,
		str(equip_data),
	])
	_check_players_ready()


@rpc("call_local", "reliable", "authority", 1)
func _start_event() -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	print_verbose("Starting event...")
	event.ended.connect(_on_event_ended)
	closed.disconnect(_loader.finish_load)
	if multiplayer.is_server():
		event.set_players_data(_players_names, _players_equip_data)
	add_child(event)
	_loader.finish_load(true)
	started.emit()
	state = State.EVENT
	print_verbose("Event loaded. Starting...")


func _check_players_ready() -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client.")
		return
	print_verbose("Waiting for players: %s." % str(_players_not_ready))
	if _players_not_ready.is_empty():
		if not _players_names.is_empty():
			($WaitPlayersTimer as Timer).stop()
			_start_event.rpc()
		else:
			print_verbose("All players disconnected, returning to lobby.")
			closed.disconnect(_loader.finish_load)
			_loader.finish_load(true)
			event.queue_free()
			# Как будто всё хорошо
			started.emit()
			ended.emit()
			state = State.LOBBY


func _init_lobby() -> void:
	var lobby_scene: PackedScene = load("uid://cmwb81du1kbtm")
	var lobby: Control = lobby_scene.instantiate()
	add_child(lobby)
	print_verbose("Created lobby.")


func _authenticate_callback(peer: int, data: PackedByteArray) -> void:
	if not peer in _scene_multiplayer.get_authenticating_peers():
		push_warning("Unexpected authenticating message: peer %d is not authenticating." % peer)
		return
	
	if not multiplayer.is_server():
		if peer != 1:
			push_warning("Unexpected authenticating message. Peer: %d." % peer)
			return
		if data.is_empty():
			push_error("Invalid data received: data is empty.")
			return
		match data[0]:
			OK:
				_scene_multiplayer.complete_auth(peer)
				return
			FailReason.DIFFERENT_VERSION:
				($ConnectingDialog as Window).hide()
				show_error("Невозможно подключиться к игре! \
Версия сервера (%s) не совпадает с твоей (%s)." % [
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
				push_error("Invalid data received: data is not AuthState.")
		close()
		return
	
	if data != Globals.version.to_utf8_buffer():
		_scene_multiplayer.send_auth(peer,
				PackedByteArray([FailReason.DIFFERENT_VERSION]) + Globals.version.to_utf8_buffer())
		print_verbose("Rejecting %d: different version (%s - local, %s - client)." % [
			peer,
			Globals.version,
			data.get_string_from_utf8(),
		])
		return
	if multiplayer.get_peers().size() + int(not Globals.headless) + 1 > max_players:
		_scene_multiplayer.send_auth(peer, PackedByteArray([FailReason.FULL_ROOM]))
		print_verbose("Rejecting %d: full room." % peer)
		return
	if state in [State.LOADING, State.EVENT]:
		_scene_multiplayer.send_auth(peer, PackedByteArray([FailReason.IN_GAME]))
		print_verbose("Rejecting %d: already in game." % peer)
		return
	
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
	multiplayer.connection_failed.disconnect(_on_connection_failed)
	multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	state = State.LOBBY
	joined.emit()
	print_verbose("Connected to server.")


func _on_connection_failed() -> void:
	($ConnectingDialog as Window).hide()
	show_error("Невозможно подключиться к серверу!")
	push_warning("Connection failed.")
	close()


func _on_peer_connected(id: int) -> void:
	# Уменьшаем время тайм-аута
	(multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(id).set_timeout(
			BASE_TIMEOUT, BASE_TIMEOUT * 2, BASE_TIMEOUT * 3)
	print_verbose("Peer connected: %d." % id)


func _on_peer_disconnected(id: int) -> void:
	if id in _players_not_ready:
		_players_not_ready.erase(id)
		_players_names.erase(id)
		_players_equip_data.erase(id)
		_check_players_ready()
	print_verbose("Peer disconnected: %d." % id)


func _on_server_disconnected() -> void:
	show_error("Разорвано соединение с сервером!")
	push_warning("Disconnected from server.")
	# Излучаем сигнал сами, потому что мы уже отключены
	closed.emit()
	close()


func _on_event_ended() -> void:
	ended.emit()
	state = State.LOBBY


func _on_wait_players_timer_timeout() -> void:
	if MultiplayerPeer.TARGET_PEER_SERVER in _players_not_ready:
		($WaitPlayersTimer as Timer).start()
		return
	for id: int in _players_not_ready.duplicate(): # чтобы корректно итерировать
		push_warning("Disconnecting peer %d for inactivity." % id)
		_scene_multiplayer.disconnect_peer(id)
		multiplayer.peer_disconnected.emit(id)
