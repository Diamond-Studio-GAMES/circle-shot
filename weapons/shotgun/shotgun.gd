extends "res://weapons/common/gun.gd"

@export var buckshot_spread: float = 30.0

func _shoot() -> void:
	_shoot_timer = shoot_interval
	ammo -= ammo_per_shot
	_anim.play("Shoot")
	_anim.seek(0, true)
	if multiplayer.is_server():
		for i: int in 6:
			var projectile_node: Attack = projectile.instantiate()
			projectile_node.global_position = _shoot_point.global_position
			projectile_node.damage = roundi(projectile_node.damage * player.damage_multiplier)
			projectile_node.rotation = player.input.aiming_direction.angle() \
					+ deg_to_rad(buckshot_spread * (1 - 0.4 * i))
			projectile_node.team = player.team
			projectile_node.who = player.player
			projectile_node.name += str(randi())
			_projectiles_parent.add_child(projectile_node)
	if ammo <= 0:
		await _anim.animation_finished
		_reload()
