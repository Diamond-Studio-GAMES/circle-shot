extends "res://game/weapons/grenades/common/grenade.gd"


func _customize_projectile(projectile: GrenadeProjectile) -> void:
	(projectile.get_node(^"Attack") as Attack).team = _player.team
	(projectile.get_node(^"Attack") as Attack).who = _player.id
	(projectile.get_node(^"Attack") as Attack).damage_multiplier = _player.damage_multiplier
	
