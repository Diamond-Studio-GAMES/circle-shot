class_name Shooter
extends Node

## Shooter core class. Manages networking.
##
## [b]Note[/b]: Connection must be closed with [method close_connection] only
## on server, because it will be automatically closed when disconnected.

signal game_created(error: int)
signal game_joined(error: int)
signal connection_closed
signal game_started(success: bool)
signal game_ended
const PORT := 14889
const MAX_CLIENTS := 10
var is_in_network := false
var game: Game
var _players_data := {}
var _players_not_ready := [] # Array[int]
@onready var _game_loader: GameLoader = $GameLoader


func _ready() -> void:
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	connection_closed.connect(_on_connection_closed)


func _process(_delta: float) -> void:
	if is_in_network:
		if multiplayer.multiplayer_peer:
			if multiplayer.multiplayer_peer.get_connection_status() != \
					MultiplayerPeer.CONNECTION_CONNECTED:
				close_connection()
		else:
			close_connection()


func create_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS - int(not Global.HEADLESS))
	if error:
		game_created.emit(error)
		return
	multiplayer.multiplayer_peer = peer
	is_in_network = true
	game_created.emit(0)


func join_game(ip: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, PORT)
	if error:
		game_joined.emit(error)
		return
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		game_joined.emit(-1)
		return
	# Workaround connected_to_server emitted, even when refusing
	for i: ENetPacketPeer in peer.host.get_peers():
		i.set_timeout(1000, 2000, 4000)
	multiplayer.multiplayer_peer = peer


func close_connection() -> void:
	multiplayer.multiplayer_peer = null
	is_in_network = false
	connection_closed.emit()


func load_game(game_id: int, map_id: int) -> void:
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.refuse_new_connections = true
		_players_not_ready = multiplayer.get_peers()
		_players_not_ready.append(1)
	_game_loader.load_game(game_id, map_id)
	var success: bool = await _game_loader.game_loaded
	if not success:
		close_connection()
		game_started.emit(false)
		return
	if multiplayer.is_server():
		if Global.HEADLESS:
			_players_not_ready.erase(1)
		else:
			_send_player_data(($GameMenu as GameMenu).get_player_data())
	else:
		_send_player_data.rpc_id(1, ($GameMenu as GameMenu).get_player_data())


func end_game() -> void:
	multiplayer.multiplayer_peer.refuse_new_connections = false
	if is_instance_valid(game):
		game.queue_free()
		game = null
	game_ended.emit()


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
	game_started.emit(true)
	game = $Game as Game
	game.game_ended.connect(end_game)
	if multiplayer.is_server():
		game.init_game(_players_data)
	else:
		game.init_game()
	_game_loader.finish_load()


func _check_players_ready() -> void:
	if not multiplayer.is_server():
		return
	if _players_not_ready.is_empty():
		_start_game.rpc()


func _on_connected_to_server() -> void:
	game_joined.emit(0)
	is_in_network = true


func _on_connection_failed() -> void:
	game_joined.emit(-1)
	multiplayer.multiplayer_peer = null


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	if id in _players_not_ready:
		_players_not_ready.erase(id)
		_players_data.erase(id)
		_check_players_ready()


func _on_connection_closed() -> void:
	if is_instance_valid(game):
		game.queue_free()
		game = null
