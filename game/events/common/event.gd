class_name Event
extends Node


signal ended
signal local_player_created(player: Player)

@export var player_scenes: Array[PackedScene]

var local_player: Player
var _started := false
var _players_equip_data := {}
var _players_names := {}
var _players_teams := {}
var _players := {}
var _hit_marker_scene: PackedScene = load("uid://c2f0n1b5sfpdh")
var _death_marker_scene: PackedScene = load("uid://blhm6uka1p287")

@onready var _chat: Chat = $UI/Main/ChatPanel
@onready var _camera: SmartCamera = $Camera


func _ready() -> void:
	$MinimapViewport.world_2d = get_viewport().find_world_2d()
	
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var entities_spawner: MultiplayerSpawner = $EntitiesSpawner
	for i: PackedScene in player_scenes:
		entities_spawner.add_spawnable_scene(i.resource_path)
	var projectiles_spawner: MultiplayerSpawner = $ProjectilesSpawner
	for i: String in Globals.items_db.spawnable_projectiles_paths:
		projectiles_spawner.add_spawnable_scene(ResourceUID.get_id_path(ResourceUID.text_to_id(i)))
	var other_spawner: MultiplayerSpawner = $OtherSpawner
	for i: String in Globals.items_db.spawnable_other_paths:
		other_spawner.add_spawnable_scene(ResourceUID.get_id_path(ResourceUID.text_to_id(i)))
	
	if multiplayer.is_server():
		_setup()
	($UI/Intro/AnimationPlayer as AnimationPlayer).play(&"Intro")


@rpc("reliable", "call_remote", "authority", 1)
func _create_hit_marker(where: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != 1 and not multiplayer.is_server():
		push_error("This method must be called only by server!")
		return
	
	var marker: Node2D = _hit_marker_scene.instantiate()
	marker.global_position = where
	$VFX.add_child(marker)


@rpc("reliable", "call_remote", "authority", 1)
func _create_kill_marker(where: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != 1 and not multiplayer.is_server():
		push_error("This method must be called only by server!")
		return
	
	var marker: Node2D = _death_marker_scene.instantiate()
	marker.global_position = where
	$VFX.add_child(marker)


func _setup() -> void:
	if not multiplayer.is_server():
		return
	_make_teams()
	_chat.players_names = _players_names
	_chat.players_teams = _players_teams
	for i: int in _players_names:
		spawn_player(i)
	_finish_setup()
	
	await get_tree().create_timer(5, false).timeout
	_start.rpc()


func set_players_data(players_names := {}, players_equip_data := {}) -> void:
	_players_names = players_names
	_players_equip_data = players_equip_data


func spawn_player(id: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var player_scene: PackedScene = _get_player_scene(id)
	var player: Player = player_scene.instantiate()
	player.global_position = _get_spawn_point(id)
	player.team = _players_teams[id]
	player.id = id
	player.player_name = _players_names[id]
	player.equip_data = _players_equip_data[id]
	player.name = "Player%d" % id
	_customize_player(player)
	_players[id] = player
	$Entities.add_child(player)
	player.damaged.connect(_on_player_damaged)
	player.killed.connect(_on_player_killed)
	if not _started:
		player.make_disarmed()
		player.make_immobile()


func set_local_player(player: Player) -> void:
	local_player = player
	local_player_created.emit(player)
	if _started:
		_camera.target = player
	else:
		if not multiplayer.is_server():
			local_player.make_disarmed()
			local_player.make_immobile()
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property($Camera as Node2D, ^"position", player.position, 4.0)
		await tween.finished
		_camera.target = player


@rpc("call_local", "reliable")
func _start() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called by server!")
		return
	
	_started = true
	_finish_start()
	if multiplayer.is_server():
		get_tree().call_group(&"Player", &"unmake_disarmed")
		get_tree().call_group(&"Player", &"unmake_immobile")
	else:
		local_player.unmake_disarmed()
		local_player.unmake_immobile()


@rpc("call_local", "reliable")
func _end() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called by server!")
		return
	
	ended.emit()
	queue_free()


func _make_teams() -> void:
	pass


func _finish_setup() -> void:
	pass


func _get_player_scene(_id: int) -> PackedScene:
	return player_scenes[0]


func _get_spawn_point(_id: int) -> Vector2:
	return Vector2()


func _customize_player(_player: Player) -> void:
	pass


func _finish_start() -> void:
	pass


func _player_killed(_who: int, _by: int) -> void:
	pass


func _player_disconnected(_id: int) -> void:
	pass


func _on_player_damaged(who: int, by: int) -> void:
	if by in _players:
		var target: Player = _players[who]
		if by == 1:
			_create_hit_marker(target.global_position)
		else:
			_create_hit_marker.rpc_id(by, target.global_position)


func _on_player_killed(who: int, by: int) -> void:
	var message_text := ""
	if by > 0:
		message_text = "[color=#%s]%s[/color] убивает игрока [color=#%s]%s[/color]!" % [
			Entity.TEAM_COLORS[_players_teams[by]].to_html(false),
			_players_names[by],
			Entity.TEAM_COLORS[_players_teams[who]].to_html(false),
			_players_names[who],
		]
	else:
		message_text = "Игрок [color=#%s]%s[/color] убит!" % [
			Entity.TEAM_COLORS[_players_teams[who]].to_html(false),
			_players_names[who],
		]
	_chat.post_message.rpc("> " + message_text)
	
	if by in _players:
		var target: Player = _players[who]
		if by == 1:
			_create_kill_marker(target.global_position)
		else:
			_create_kill_marker.rpc_id(by, target.global_position)
	
	_player_killed(who, by)
	_players.erase(who)


func _on_peer_disconnected(id: int) -> void:
	var message_text: String = "Игрок [color=#%s]%s[/color] отключился!" % [
		Entity.TEAM_COLORS[_players_teams[id]].to_html(false),
		_players_names[id],
	]
	_chat.post_message.rpc("> " + message_text)
	if id in _players:
		if is_instance_valid(_players[id]):
			_players[id].queue_free()
		_players.erase(id)
	_players_names.erase(id)
	_players_equip_data.erase(id)
	_players_teams.erase(id)
	if _players_names.is_empty():
		_end.rpc()
		return
	_player_disconnected(id)


func _on_leave_game_pressed() -> void:
	Globals.main.game.close()
