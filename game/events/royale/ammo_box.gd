extends Area2D

@export_range(0.0, 1.0) var ammo_restore_percent := 0.2

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	var player := body as Player
	if not player:
		return
	player.add_ammo_to_weapon.rpc(Weapon.Type.LIGHT, ammo_restore_percent)
	player.add_ammo_to_weapon.rpc(Weapon.Type.HEAVY, ammo_restore_percent)
	player.add_ammo_to_weapon.rpc(Weapon.Type.SUPPORT, ammo_restore_percent)
	player.add_ammo_to_weapon.rpc(Weapon.Type.MELEE, ammo_restore_percent)
	queue_free()


func _on_despawn_timer_timeout() -> void:
	($AnimationPlayer as AnimationPlayer).play(&"Despawn")
	if multiplayer.is_server():
		await ($AnimationPlayer as AnimationPlayer).animation_finished
		queue_free()
