extends Event


@export var heal_box_scene: PackedScene
@export var heal_box_spawn_interval: float = 15.0
var _spawn_counter: int = 0
var _heal_box_counter: int = 0
var _alive_players: Array
var _ended := false
@onready var _spawn_points: Array[Node] = $Map/SpawnPoints.get_children()
@onready var _heal_box_points: Array[Node] = $Map/HealPoints.get_children()
@onready var _other_parent: Node = get_tree().get_first_node_in_group(&"OtherParent")


func _finish_start() -> void:
	if multiplayer.is_server():
		($HealBoxSpawnTimer as Timer).start()
		_alive_players = _players_names.keys()
		_set_alive_players.rpc(_alive_players.size())
		for i: Player in get_tree().get_nodes_in_group(&"Player"):
			i.died.connect(_on_player_died)
		_check_winner()
	for smoke: Node2D in $PoisonSmoke.get_children():
		var tween: Tween = smoke.create_tween()
		tween.tween_property(smoke, "position", Vector2.ZERO, 400.0)


func _make_teams() -> void:
	_spawn_points.shuffle()
	_heal_box_points.shuffle()
	var counter: int = 0
	for i: int in _players_names:
		_players_teams[i] = counter
		counter += 1


func _get_spawn_point(_id: int) -> Vector2:
	var pos := (_spawn_points[_spawn_counter] as Node2D).global_position
	_spawn_counter += 1
	return pos


func _player_disconnected(id: int) -> void:
	_alive_players.erase(id)
	_set_alive_players.rpc(_alive_players.size())
	_check_winner()


@rpc("reliable", "call_local")
func _show_winner(winner: int, winner_name: String) -> void:
	_ended = true
	if winner == multiplayer.get_unique_id():
		($EventUI/Main/GameEnd as Label).text = "ТЫ ПОБЕДИЛ!!!"
	else:
		($EventUI/Main/GameEnd as Label).text = "ПОБЕДИТЕЛЬ: %s" % winner_name
	($EventUI/Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"Victory")


@rpc("call_local", "reliable")
func _set_alive_players(count: int) -> void:
	($EventUI/Main/PlayerCounter as Label).text = "Осталось игроков: %d" % count


func _spawn_heal_box() -> void:
	var spawn_position: Vector2 = (_heal_box_points[_heal_box_counter] as Node2D).global_position
	var heal_box: Node2D = heal_box_scene.instantiate()
	heal_box.position = spawn_position
	heal_box.name += str(randi())
	_other_parent.add_child(heal_box)
	_heal_box_counter += 1
	if _heal_box_counter == _heal_box_points.size():
		_heal_box_counter = 0
		_heal_box_points.shuffle()


func _check_winner() -> void:
	if _alive_players.size() != 1:
		return
	var winner_id: int = _alive_players[0]
	var winner_name: String = _players_names[winner_id]
	_show_winner.rpc(winner_id, winner_name)
	($HealBoxSpawnTimer as Timer).stop()
	await get_tree().create_timer(6.5).timeout
	get_tree().call_group(&"Player", &"queue_free")
	for i: Node in get_tree().get_first_node_in_group(&"ProjectilesParent").get_children():
		i.queue_free()
	for i: Node in get_tree().get_first_node_in_group(&"OtherParent").get_children():
		i.queue_free()
	await get_tree().create_timer(0.5).timeout
	_end.rpc()


func _on_heal_box_spawn_timer_timeout() -> void:
	_spawn_heal_box()
	if _players.is_empty():
		return
	($HealBoxSpawnTimer as Timer).start(heal_box_spawn_interval / _players.size())


func _on_watching_player_died(_who: int, player: Player) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"Player")
	players.erase(player)
	if players.is_empty():
		return
	var next_player: Player = players[0]
	next_player.died.connect(_on_watching_player_died.bind(next_player))
	_camera.target = next_player


func _on_local_player_died(_who: int) -> void:
	if _ended:
		return
	($EventUI/Main/GameEnd as Label).text = "ПОРАЖЕНИЕ!"
	($EventUI/Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"Defeat")


func _on_player_died(who: int) -> void:
	_alive_players.erase(who)
	_set_alive_players.rpc(_alive_players.size())
	_check_winner()


func _on_local_player_created(player: Player) -> void:
	player.died.connect(_on_watching_player_died.bind(player))
	player.died.connect(_on_local_player_died)
