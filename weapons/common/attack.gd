class_name Attack
extends Area2D

@export var damage: int
@export var who: int = -1
@export var team: int = -1

func _ready() -> void:
	monitorable = false
	if not multiplayer.is_server():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _damage_player(player: Player, amount: int = damage) -> void:
	player.damage(amount, who if who > 0 else player.player)


func _on_body_entered(_body: Node2D) -> void:
	pass


func _on_body_exited(_body: Node2D) -> void:
	pass
