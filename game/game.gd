class_name Game
extends Node

@warning_ignore("unused_signal") # Connected dynamically
signal game_ended

var _players_data := {}
var _players := {}

# Why _ready don't work???
func _enter_tree() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	var player_spawner: MultiplayerSpawner = $PlayerSpawner
	for i: SkinConfig in Global.items_db.skins:
		player_spawner.add_spawnable_scene(ResourceUID.get_id_path(ResourceUID.text_to_id(i.skin_path)))
	var projectiles_spawner: MultiplayerSpawner = $ProjectilesSpawner
	for i: String in Global.items_db.spawnable_projectiles:
		projectiles_spawner.add_spawnable_scene(ResourceUID.get_id_path(ResourceUID.text_to_id(i)))
	var vfx_spawner: MultiplayerSpawner = $VFXSpawner
	for i: String in Global.items_db.spawnable_vfx:
		vfx_spawner.add_spawnable_scene(ResourceUID.get_id_path(ResourceUID.text_to_id(i)))


func start_game(players_data := {}) -> void:
	if not multiplayer.is_server():
		return
	_players_data = players_data
	_make_teams()
	for i: int in _players_data:
		spawn_player(i)


func spawn_player(id: int) -> void:
	if not multiplayer.is_server():
		return
	var data: Array = _players_data[id]
	var player_scene: PackedScene = load(Global.items_db.skins[data[1]].skin_path)
	var player: Player = player_scene.instantiate()
	player.global_position = _get_spawn_point(id)
	player.team = data[6]
	player.player = id
	player.player_name = data[0]
	player.weapons_data = data.slice(2, 6)
	player.name = "Player%d" % id
	_players[id] = player
	$Players.add_child(player, true)


func _make_teams() -> void:
	for i: int in _players_data:
		_players_data[i].append(0)


func _get_spawn_point(_id: int) -> Vector2:
	return Vector2()


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	if id in _players:
		_players[id].queue_free()
		_players.erase(id)
	_players_data.erase(id)
