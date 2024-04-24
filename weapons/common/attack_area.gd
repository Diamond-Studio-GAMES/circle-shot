extends Attack


@export var interval: float = 1.0
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
