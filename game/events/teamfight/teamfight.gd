class_name Teamfight
extends Event

## Событие "Командный бой".

## Длительность матча.
@export var match_time: int = 180
## Время, через которое возвращаются павшие игроки.
@export var comeback_time: int = 3

var red_kills: int = 0
var blue_kills: int = 0
var _spawn_counter_red: int = 0
var _spawn_counter_blue: int = 0
var _time_remained: int

@onready var _spawn_points_red: Array[Node] = $Map/SpawnPoints0.get_children()
@onready var _spawn_points_blue: Array[Node] = $Map/SpawnPoints1.get_children()
@onready var _teamfight_ui: TeamfightUI = $UI


func _initialize() -> void:
	_teamfight_ui.set_time(match_time)
	_time_remained = match_time
	if multiplayer.is_server():
		_spawn_counter_red = randi() % 5
		_spawn_counter_blue = randi() % 5


func _finish_setup() -> void:
	_teamfight_ui.set_kills.rpc(red_kills, blue_kills)


func _finish_start() -> void:
	if multiplayer.is_server():
		($MatchTimer as Timer).start()


func _make_teams() -> void:
	_spawn_points_blue.shuffle()
	_spawn_points_red.shuffle()
	
	var next_team: int = -1
	for player: int in _players_names:
		if next_team < 0:
			var team: int = randi() % 2
			_players_teams[player] = team
			next_team = 1 - team
		else:
			_players_teams[player] = next_team
			next_team = -1


func _get_spawn_point(id: int) -> Vector2:
	var pos: Vector2
	if _players_teams[id] == 0:
		pos = (_spawn_points_red[_spawn_counter_red % 5] as Node2D).global_position
		_spawn_counter_red += 1
	else:
		pos = (_spawn_points_blue[_spawn_counter_blue % 5] as Node2D).global_position
		_spawn_counter_blue += 1
	return pos


func _player_killed(who: int, _by: int) -> void:
	if _players_teams[who] == 0:
		blue_kills += 1
	else:
		red_kills += 1
	_teamfight_ui.set_kills.rpc(red_kills, blue_kills)
	_respawn_player(who)


func _player_disconnected(_who: int) -> void:
	if _time_remained <= 0:
		return
	# Недостаточно участников команд
	if not (_players_teams.find_key(0) and _players_teams.find_key(1)):
		_time_remained = 1


@rpc("reliable", "call_local", "authority", 3)
func _update_time(remained: int) -> void:
	_teamfight_ui.set_time(remained)


@rpc("reliable", "call_local", "authority", 3)
func _freeze_players() -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	get_tree().call_group(&"Player", &"make_disarmed")
	get_tree().call_group(&"Player", &"make_immobile")
	get_tree().call_group(&"Player", &"make_immune")


func _respawn_player(id: int) -> void:
	await get_tree().create_timer(comeback_time, false).timeout
	if _time_remained > 0 and id in _players_names:
		spawn_player(id)


func _determine_winner() -> void:
	if not _players_teams.find_key(0): # Нет красных больше
		_teamfight_ui.show_winner.rpc(1)
	elif not _players_teams.find_key(1): # Нет синих больше
		_teamfight_ui.show_winner.rpc(0)
	elif red_kills > blue_kills:
		_teamfight_ui.show_winner.rpc(0)
	elif blue_kills > red_kills:
		_teamfight_ui.show_winner.rpc(1)
	else:
		_teamfight_ui.show_winner.rpc(-1)
	_freeze_players.rpc()
	await get_tree().create_timer(6.5).timeout
	cleanup()
	await get_tree().create_timer(0.5).timeout
	end.rpc()


func _on_local_player_created(player: Player) -> void:
	player.died.connect(_on_local_player_died)


func _on_local_player_died(_who: int) -> void:
	_teamfight_ui.show_comeback(comeback_time)


func _on_match_timer_timeout() -> void:
	_time_remained -= 1
	_update_time.rpc(_time_remained)
	if _time_remained <= 0:
		($MatchTimer as Timer).stop()
		_determine_winner()
