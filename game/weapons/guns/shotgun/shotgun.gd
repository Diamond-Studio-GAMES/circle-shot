extends "res://game/weapons/guns/common/gun.gd"

@export var buckshot_in_shot: int = 6

func reload() -> void:
	if ammo_in_stock < 1:
		return
	
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"rotation", 0.0, to_aim_time)
	_anim.play(&"StartReload")
	
	var anim_name: StringName = await _anim.animation_finished
	if anim_name != &"StartReload":
		return
	
	while ammo != ammo_per_load:
		if ammo_in_stock < 1:
			break
		
		_anim.play(&"Reload")
		anim_name = await _anim.animation_finished
		if anim_name != &"Reload":
			return
		
		ammo += 1
		ammo_in_stock -= 1
		_player.ammo_text_updated.emit(get_ammo_text())
	
	_anim.play(&"EndReload")
	anim_name = await _anim.animation_finished
	if anim_name != &"EndReload":
		return
	
	_anim.play(&"PostReload")
	tween = create_tween()
	tween.tween_property(self, ^"rotation", _calculate_aim_direction(), to_aim_time)


func _create_projectile() -> void:
	for i: int in buckshot_in_shot:
		var projectile: Attack = projectile_scene.instantiate()
		projectile.global_position = _shoot_point.global_position
		projectile.damage = roundi(projectile.damage * _player.damage_multiplier)
		projectile.rotation = _player.player_input.aim_direction.angle() + deg_to_rad(
				_calculate_spread() * (-1 + 2.0 / (buckshot_in_shot - 1) * i)
		)
		projectile.team = _player.team
		projectile.who = _player.id
		projectile.name += str(randi())
		_projectiles_parent.add_child(projectile)
