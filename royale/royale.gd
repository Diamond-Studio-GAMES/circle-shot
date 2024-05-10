extends Game


@export var heal_box: PackedScene
@export var heal_box_spawn_interval: float = 15.0
var _spawn_points: Array[Node]
var _spawn_counter := 0
var _heal_box_points: Array[Node]
var _heal_box_counter: int = 0
var _alive_players: Array
var _game_won := false
@onready var _other_parent: Node = get_tree().get_first_node_in_group(&"OtherParent")


func _start_game() -> void:
	super()
	if multiplayer.is_server():
		($HealBoxSpawnTimer as Timer).start()
		_alive_players = _players_data.keys()
		for i: Player in get_tree().get_nodes_in_group(&"Player"):
			i.died.connect(_on_player_died)
	for smoke: Node2D in $PoisonSmoke.get_children():
		var tween: Tween = smoke.create_tween()
		tween.tween_property(smoke, "position", Vector2.ZERO, 400.0)


func _make_teams() -> void:
	_spawn_points = $Map/SpawnPoints.get_children()
	_spawn_points.shuffle()
	_heal_box_points = $Map/HealPoints.get_children()
	_heal_box_points.shuffle()
	var counter := 0
	for i: int in _players_data:
		_players_data[i].append(counter)
		counter += 1


func _get_spawn_point(_id: int) -> Vector2:
	var pos := (_spawn_points[_spawn_counter] as Node2D).global_position
	_spawn_counter += 1
	return pos


@rpc("reliable")
func _show_winner(winner: int, winner_name: String) -> void:
	_game_won = true
	if winner == multiplayer.get_unique_id():
		($GameUI/Main/GameEnd as Label).text = "ТЫ ПОБЕДИЛ!!!"
	else:
		($GameUI/Main/GameEnd as Label).text = "ПОБЕДИТЕЛЬ: %s" % winner_name
	($GameUI/Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"Victory")


func _spawn_heal_box() -> void:
	var spawn_position: Vector2 = (_heal_box_points[_heal_box_counter] as Node2D).global_position
	var heal_box_node: Node2D = heal_box.instantiate()
	heal_box_node.position = spawn_position
	heal_box_node.name += str(randi())
	_other_parent.add_child(heal_box_node)
	_heal_box_counter += 1
	if _heal_box_counter == _heal_box_points.size():
		_heal_box_counter = 0
		_heal_box_points.shuffle()


func _check_winner() -> void:
	if _alive_players.size() == 1:
		var winner_id: int = _alive_players[0]
		var winner_name: String = _players_data[winner_id][0]
		_show_winner.rpc(winner_id, winner_name)
		if not Global.HEADLESS:
			_show_winner(winner_id, winner_name)
	await get_tree().create_timer(7.5).timeout
	end_game.rpc()


func _on_heal_box_spawn_timer_timeout() -> void:
	_spawn_heal_box()
	if _players.is_empty():
		return
	($HealBoxSpawnTimer as Timer).start(heal_box_spawn_interval / _players.size())


func _on_local_player_created(player: Player) -> void:
	player.died.connect(_on_watching_player_died.bind(player))
	player.died.connect(_on_local_player_died)


func _on_watching_player_died(_who: int, player: Player) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"Player")
	players.erase(player)
	if players.is_empty():
		return
	var next_player: Player = players[0]
	next_player.died.connect(_on_watching_player_died.bind(next_player))
	next_player.remote_transform.remote_path = next_player.remote_transform.get_path_to($Camera)
	next_player.remote_transform.force_update_cache()


func _on_local_player_died(_who: int) -> void:
	if _game_won:
		return
	($GameUI/Main/GameEnd as Label).text = "ПОРАЖЕНИЕ!"
	($GameUI/Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"Defeat")


func _on_player_died(who: int) -> void:
	_alive_players.erase(who)
	_check_winner()


func _on_peer_disconnected(id: int) -> void:
	_alive_players.erase(id)
	_check_winner()
	super(id)
