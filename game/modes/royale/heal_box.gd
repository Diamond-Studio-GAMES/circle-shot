extends Area2D

@export var heal_amount: int = 10

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	var player := body as Player
	if not player:
		return
	player.heal(heal_amount)
	queue_free()


func _on_despawn_timer_timeout() -> void:
	($AnimationPlayer as AnimationPlayer).play(&"Despawn")
	if multiplayer.is_server():
		await ($AnimationPlayer as AnimationPlayer).animation_finished
		queue_free()
