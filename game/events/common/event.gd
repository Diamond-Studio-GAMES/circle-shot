class_name Event
extends Node


signal ended
signal local_player_created(player: Player)
signal local_team_set(team: int)

const SPAWN_POINT_RANDOMNESS := 40.0

@export var player_scenes: Array[PackedScene]

var local_player: Player
var local_team: int = -1
var started := false
var _players_equip_data: Dictionary[int, Array]
var _players_names: Dictionary[int, String]
var _players_teams: Dictionary[int, int]
var _players_skill_vars: Dictionary[int, Array]
var _players: Dictionary[int, Player]
var _hit_marker_scene: PackedScene = load("uid://c2f0n1b5sfpdh")
var _death_marker_scene: PackedScene = load("uid://blhm6uka1p287")

@onready var camera: SmartCamera = $Camera
@onready var _event_ui: EventUI = $UI


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# TODO: когда исправят UID???
	var entities_spawner: MultiplayerSpawner = $EntitiesSpawner
	for i: PackedScene in player_scenes:
		entities_spawner.add_spawnable_scene(i.resource_path)
	var projectiles_spawner: MultiplayerSpawner = $ProjectilesSpawner
	for i: String in Globals.items_db.spawnable_projectiles_paths:
		projectiles_spawner.add_spawnable_scene(ResourceUID.get_id_path(ResourceUID.text_to_id(i)))
	var other_spawner: MultiplayerSpawner = $OtherSpawner
	for i: String in Globals.items_db.spawnable_other_paths:
		other_spawner.add_spawnable_scene(ResourceUID.get_id_path(ResourceUID.text_to_id(i)))
	
	_initialize()
	if multiplayer.is_server():
		_setup()
	
	_event_ui.show_intro()


@rpc("reliable", "call_local", "authority", 1)
func _create_hit_marker(where: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	if Globals.get_setting_bool("vibration_hit"):
		Input.vibrate_handheld(100, 0.15)
	if Globals.get_setting_bool("hit_markers"):
		var marker: Node2D = _hit_marker_scene.instantiate()
		marker.global_position = where
		$VFX.add_child(marker)


@rpc("reliable", "call_local", "authority", 1)
func _create_kill_marker(where: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	if Globals.get_setting_bool("vibration_hit"):
		Input.vibrate_handheld(400, 0.3)
	if Globals.get_setting_bool("hit_markers"):
		var marker: Node2D = _death_marker_scene.instantiate()
		marker.global_position = where
		$VFX.add_child(marker)


func set_players_data(players_names: Dictionary[int, String],
		players_equip_data: Dictionary[int, Array]) -> void:
	_players_names = players_names
	_players_equip_data = players_equip_data


func spawn_player(id: int) -> void:
	var player_scene: PackedScene = _get_player_scene(id)
	var player: Player = player_scene.instantiate()
	player.global_position = _get_spawn_point(id) + Vector2(
			randf_range(-SPAWN_POINT_RANDOMNESS, SPAWN_POINT_RANDOMNESS),
			randf_range(-SPAWN_POINT_RANDOMNESS, SPAWN_POINT_RANDOMNESS)
	)
	player.team = _players_teams[id]
	player.id = id
	player.player_name = _players_names[id]
	player.equip_data = _players_equip_data[id]
	if id in _players_skill_vars:
		player.skill_vars = _players_skill_vars[id]
	player.name = "Player%d" % id
	_customize_player(player)
	_players[id] = player
	$Entities.add_child(player)
	player.damaged.connect(_on_player_damaged)
	player.killed.connect(_on_player_killed)
	if not started:
		player.make_disarmed()
		player.make_immobile()


func set_local_player(player: Player) -> void:
	local_player = player
	local_player_created.emit(player)
	set_local_team(player.team)
	if started:
		camera.target = player
	else:
		if not multiplayer.is_server():
			local_player.make_disarmed()
			local_player.make_immobile()
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property($Camera as Node2D, ^"position", player.position, 4.0)
		await tween.finished
		camera.target = player


func set_local_team(team: int) -> void:
	local_team = team
	local_team_set.emit()


@rpc("call_local", "reliable")
func _start() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	started = true
	_finish_start()
	if multiplayer.is_server():
		get_tree().call_group(&"Player", &"unmake_disarmed")
		get_tree().call_group(&"Player", &"unmake_immobile")
	else:
		local_player.unmake_disarmed()
		local_player.unmake_immobile()
	
	if Globals.get_setting_bool("custom_tracks") \
			and not Globals.main.loaded_custom_tracks.is_empty():
		($Music as AudioStreamPlayer).stream = \
				Globals.main.loaded_custom_tracks.values().pick_random()
		($Music as AudioStreamPlayer).play()


@rpc("call_local", "reliable")
func _end() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	ended.emit()
	queue_free()


func _setup() -> void:
	_make_teams()
	_event_ui.chat.players_names = _players_names
	_event_ui.chat.players_teams = _players_teams
	for i: int in _players_names:
		spawn_player(i)
	_finish_setup()
	
	await get_tree().create_timer(5, false).timeout
	_start.rpc()


func _initialize() -> void:
	pass


func _make_teams() -> void:
	pass


func _finish_setup() -> void:
	pass


func _finish_start() -> void:
	pass


func _get_player_scene(_id: int) -> PackedScene:
	return player_scenes[0]


func _get_spawn_point(_id: int) -> Vector2:
	return Vector2()


func _customize_player(_player: Player) -> void:
	pass


func _player_killed(_who: int, _by: int) -> void:
	pass


func _player_disconnected(_id: int) -> void:
	pass


func _on_player_damaged(who: int, by: int) -> void:
	if by in _players:
		var target: Player = _players[who]
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
		message_text = "[color=#%s]%s[/color] умирает!" % [
			Entity.TEAM_COLORS[_players_teams[who]].to_html(false),
			_players_names[who],
		]
	_event_ui.chat.post_message.rpc("> " + message_text)
	
	if by in _players:
		var target: Player = _players[who]
		_create_kill_marker.rpc_id(by, target.global_position)
	
	_players_skill_vars[who] = _players[who].skill_vars
	_player_killed(who, by)
	_players.erase(who)


func _on_peer_disconnected(id: int) -> void:
	var message_text: String = "[color=#%s]%s[/color] отключается!" % [
		Entity.TEAM_COLORS[_players_teams[id]].to_html(false),
		_players_names[id],
	]
	_event_ui.chat.post_message.rpc("> " + message_text)
	if id in _players:
		if is_instance_valid(_players[id]):
			_players[id].queue_free()
		_players.erase(id)
	_players_names.erase(id)
	_players_equip_data.erase(id)
	_players_teams.erase(id)
	_players_skill_vars.erase(id)
	if _players_names.is_empty():
		_end.rpc()
		return
	_player_disconnected(id)
