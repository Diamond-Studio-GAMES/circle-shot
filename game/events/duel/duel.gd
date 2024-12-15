class_name Duel
extends Event

## Событие "Дуэль".

## Время, за которое ядовитый дым покроет всю карту.
@export var poison_smoke_time := 400.0

var _red_rounds_won: int = 0
var _blue_rounds_won: int = 0
var _current_round: int = 0
var _poison_smokes_scene: PackedScene = preload("uid://dkhofq2eo6jbk")

@onready var _duel_ui: DuelUI = $UI


func _make_teams() -> void:
	var prev_team: int = -1
	var players: Array[int] = _players_names.keys()
	players.shuffle()
	for player: int in players:
		if prev_team < 0:
			_players_teams[player] = randi() % 2
			prev_team = _players_teams[player]
		else:
			_players_teams[player] = 1 - prev_team


func _finish_start() -> void:
	if multiplayer.is_server():
		_start_round.rpc()


func _get_spawn_point(id: int) -> Vector2:
	if _players_teams[id] == 0:
		return ($Map/SpawnPoint0 as Node2D).global_position
	else:
		return ($Map/SpawnPoint1 as Node2D).global_position


func _customize_player(player: Player) -> void:
	match _current_round:
		0:
			player.equip_data[2] = -1
		1:
			player.equip_data[1] = -1
		2:
			player.equip_data[1] = -1
			player.equip_data[2] = -1


func _player_killed(who: int, _by: int) -> void:
	var team_won: int = 1 - _players_teams[who]
	if team_won == 1:
		_blue_rounds_won += 1
	else:
		_red_rounds_won += 1
	if _current_round == 2 or _blue_rounds_won >= 2 or _red_rounds_won >= 2:
		if _blue_rounds_won > _red_rounds_won:
			_end_round.rpc(team_won, _players_teams.find_key(1), true)
		else:
			_end_round.rpc(team_won, _players_teams.find_key(0), true)
	else:
		_end_round.rpc(team_won, _players_teams.find_key(team_won))


func _player_disconnected(_id: int) -> void:
	if _current_round > 2: # Игра завершена
		return
	_end_round.rpc(_players_teams.values()[0], _players_teams.keys()[0], true)


@rpc("reliable", "call_local", "authority", 3)
func _start_round() -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	_duel_ui.start_round(_current_round)
	var smokes: Node2D = _poison_smokes_scene.instantiate()
	add_child(smokes)
	for smoke: Node2D in smokes.get_children():
		var tween: Tween = smoke.create_tween()
		tween.tween_property(smoke, ^":position", Vector2.ZERO, poison_smoke_time)
	var tween: Tween = smokes.create_tween()
	tween.tween_property(smokes, ^":modulate", Color.WHITE, )


@rpc("reliable", "call_local", "authority", 3)
func _end_round(win_team: int, winner: int, end_event := false) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	_duel_ui.end_round(_current_round, win_team, winner, end_event)
	_current_round += 1
	$PoisonSmokes.queue_free()
	get_tree().call_group(&"Player", &"make_disarmed")
	get_tree().call_group(&"Player", &"make_immobile")
	get_tree().call_group(&"Player", &"make_immune")
	if not multiplayer.is_server():
		return
	
	await get_tree().create_timer(3.5).timeout
	if end_event:
		await get_tree().create_timer(3.0).timeout
	cleanup()
	await get_tree().create_timer(0.5).timeout
	if end_event:
		end.rpc()
	else:
		for player: int in _players_names:
			spawn_player(player)
		_start_round.rpc()
