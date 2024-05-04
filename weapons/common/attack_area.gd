extends Attack

@export var damage_interval: float = 1.0
var _players := {}

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer:
		if not multiplayer.is_server():
			return
	else:
		return
	for i: Player in _players:
		_players[i] -= delta
		if _players[i] <= 0:
			_damage_player(i)
			_players[i] = damage_interval


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
