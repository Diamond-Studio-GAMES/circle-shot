extends "res://game/weapons/grenades/common/grenade.gd"


func _customize_projectile(projectile: GrenadeProjectile) -> void:
	(projectile.get_node(^"Explosion/Attack") as Attack).team = _player.team
