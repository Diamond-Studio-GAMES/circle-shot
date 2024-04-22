extends Area2D

@export var damage: int = 10
@export var interval: float = 1.0
@export var who := -1
@export var team := -1
@export_flags_2d_physics var target_mask := 2
var _players := {}

func _ready() -> void:
	collision_layer = 4
	collision_mask = target_mask
	monitorable = false
	if not multiplayer.is_server():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer:
		if not multiplayer.is_server():
			return
	else:
		return
	for i: Player in _players:
		_players[i] -= delta
		if _players[i] <= 0:
			i.damage(damage, who if who > 0 else i.player)
			_players[i] = interval


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if not player:
		return
	if player.team == team:
		return
	_players[player] = 0.01


func _on_body_exited(body: Node2D) -> void:
	var player := body as Player
	if not player:
		return
	_players.erase(player)
