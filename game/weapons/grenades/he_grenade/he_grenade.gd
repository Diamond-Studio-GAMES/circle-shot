extends "res://game/weapons/grenades/common/grenade.gd"


func _customize_projectile(projectile: GrenadeProjectile) -> void:
	for i: Attack in projectile.get_node(^"Explosion/Attacks").get_children():
		i.who = _player.id
		i.team = _player.team
		i.damage_multiplier = _player.damage_multiplier
