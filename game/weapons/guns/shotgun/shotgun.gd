extends "res://game/weapons/guns/common/gun.gd"

@export var buckshot_in_shot: int = 6
var _reloading := false

func can_reload() -> bool:
	return ammo != ammo_per_load and ammo_in_stock > 0 and can_shoot() \
			and _shoot_timer <= 0.0 and not _reloading


func reload() -> void:
	_reloading = true
	block_shooting()
	_anim.play(&"StartReload")
	
	var anim_name: StringName = await _anim.animation_finished
	unlock_shooting()
	if anim_name != &"StartReload":
		_reloading = false
		return
	
	while ammo != ammo_per_load:
		if ammo_in_stock < 1:
			break
		
		_anim.play(&"Reload")
		anim_name = await _anim.animation_finished
		if anim_name != &"Reload":
			_reloading = false
			return
		
		ammo += 1
		ammo_in_stock -= 1
		_player.ammo_text_updated.emit(get_ammo_text())
	
	block_shooting()
	_anim.play(&"EndReload")
	anim_name = await _anim.animation_finished
	_reloading = false
	if anim_name != &"EndReload":
		unlock_shooting()
		return
	
	_anim.play(&"PostReload")
	await _anim.animation_finished
	unlock_shooting()


func _create_projectile() -> void:
	for i: int in buckshot_in_shot:
		var projectile: Attack = projectile_scene.instantiate()
		projectile.global_position = _shoot_point.global_position
		projectile.damage_multiplier = _player.damage_multiplier
		projectile.rotation = _player.player_input.aim_direction.angle() + deg_to_rad(
				_calculate_spread() * (-1 + 2.0 / (buckshot_in_shot - 1) * i)
		)
		projectile.team = _player.team
		projectile.who = _player.id
		projectile.name += str(randi())
		_projectiles_parent.add_child(projectile)
