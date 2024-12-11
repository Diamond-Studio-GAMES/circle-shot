class_name Event
extends Node


signal ended
signal local_player_created(player: Player)
signal local_team_set(team: int)

const HIT_VIBRATION_INTENSITY := 0.07
const HIT_VIBRATION_DURATION_MS: int = 100
const KILL_VIBRATION_INTENSITY := 0.15
const KILL_VIBRATION_DURATION_MS: int = 300

@export var spawn_point_randomness := 40.0
@export var player_scenes: Array[PackedScene]

var local_player: Player
var local_team: int = -1
var started := false
var _players_equip_data: Dictionary[int, Array]
var _players_names: Dictionary[int, String]
var _players_teams: Dictionary[int, int]
var _players_skill_vars: Dictionary[int, Array]
var _players: Dictionary[int, Player]

var _vibration_enabled: bool
var _hit_marker_scene: PackedScene
var _death_marker_scene: PackedScene

@onready var _event_ui: EventUI = $UI


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if Globals.get_setting_bool("hit_markers"):
		_hit_marker_scene = load("uid://c2f0n1b5sfpdh")
		_death_marker_scene = load("uid://blhm6uka1p287")
	_vibration_enabled = Globals.get_setting_bool("vibration")
	
	# TODO: когда исправят UID???
	var entities_spawner: MultiplayerSpawner = $EntitiesSpawner
	for scene: PackedScene in player_scenes:
		entities_spawner.add_spawnable_scene(scene.resource_path)
	var projectiles_spawner: MultiplayerSpawner = $ProjectilesSpawner
	for path: String in Globals.items_db.spawnable_projectiles_paths:
		projectiles_spawner.add_spawnable_scene(
				ResourceUID.get_id_path(ResourceUID.text_to_id(path)))
	var other_spawner: MultiplayerSpawner = $OtherSpawner
	for path: String in Globals.items_db.spawnable_other_paths:
		other_spawner.add_spawnable_scene(ResourceUID.get_id_path(ResourceUID.text_to_id(path)))
	
	_initialize()
	if multiplayer.is_server():
		_setup()
	
	_event_ui.show_intro()


@rpc("reliable", "call_local", "authority", 6)
func _register_hit(where: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	if _vibration_enabled:
		Input.vibrate_handheld(HIT_VIBRATION_DURATION_MS, HIT_VIBRATION_INTENSITY)
	if _death_marker_scene:
		var marker: Node2D = _hit_marker_scene.instantiate()
		marker.position = where
		$Vfx.add_child(marker)


@rpc("reliable", "call_local", "authority", 6)
func _register_kill(where: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	if _vibration_enabled:
		Input.vibrate_handheld(KILL_VIBRATION_DURATION_MS, KILL_VIBRATION_INTENSITY)
	if _death_marker_scene:
		var marker: Node2D = _death_marker_scene.instantiate()
		marker.position = where
		$Vfx.add_child(marker)


func set_players_data(players_names: Dictionary[int, String],
		players_equip_data: Dictionary[int, Array]) -> void:
	_players_names = players_names
	_players_equip_data = players_equip_data


func spawn_player(id: int) -> void:
	var player: Player = _get_player_scene(id).instantiate()
	player.position = _get_spawn_point(id) + Vector2(
			randf_range(-spawn_point_randomness, spawn_point_randomness),
			randf_range(-spawn_point_randomness, spawn_point_randomness)
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
	
	var camera: SmartCamera = $Camera
	if started:
		camera.pan_to_target(player, 0.3)
	else:
		if not multiplayer.is_server():
			local_player.make_disarmed()
			local_player.make_immobile()
		camera.pan_to_target(player, 4.0)


func set_local_team(team: int) -> void:
	local_team = team
	local_team_set.emit(team)


@rpc("call_local", "reliable", "authority", 3)
func _start() -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	_finish_start()
	started = true
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
	print_verbose("Event started.")


@rpc("call_local", "reliable", "authority", 3)
func _end() -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	print_verbose("Event ended.")
	ended.emit()
	queue_free()


func _setup() -> void:
	_make_teams()
	_event_ui.chat.players_names = _players_names
	_event_ui.chat.players_teams = _players_teams
	for player_id: int in _players_names:
		spawn_player(player_id)
	_finish_setup()
	
	await get_tree().create_timer(5.0, false).timeout
	_start.rpc()


func _cleanup() -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client.")
		return
	get_tree().call_group(&"Entity", &"queue_free")
	for projectile: Node in $Projectiles.get_children():
		projectile.queue_free()
	for other: Node in $Other.get_children():
		other.queue_free()


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
		_register_hit.rpc_id(by, target.global_position)


func _on_player_killed(who: int, by: int) -> void:
	var message_text: String
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
		_register_kill.rpc_id(by, target.global_position)
	
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
