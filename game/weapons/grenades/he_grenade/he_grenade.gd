extends Grenade


func _customize_projectile(projectile: GrenadeProjectile) -> void:
	for attack: Attack in projectile.get_node(^"Explosion/Attacks").get_children():
		attack.who = _player.id
		attack.team = _player.team
		attack.damage_multiplier = _player.damage_multiplier
