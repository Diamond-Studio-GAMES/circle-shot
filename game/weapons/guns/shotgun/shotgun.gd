extends Gun

@export var buckshot_in_shot: int = 6
var _reloading := false
var _interrupt_reload := false

func _process(delta: float) -> void:
	super(delta)
	if _reloading and _player.player_input.shooting:
		_interrupt_reload = true


func reload() -> void:
	_reloading = true
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"rotation", 0.0, to_aim_time)
	block_shooting()
	_anim.play(&"StartReload")
	
	var anim_name: StringName = await _anim.animation_finished
	if anim_name != &"StartReload":
		_reloading = false
		_interrupt_reload = false
		unlock_shooting()
		return
	
	while ammo != ammo_per_load and ammo_in_stock >= 0:
		_anim.play(&"Reload")
		anim_name = await _anim.animation_finished
		if anim_name != &"Reload":
			_reloading = false
			_interrupt_reload = false
			unlock_shooting()
			return
		
		ammo += 1
		ammo_in_stock -= 1
		_player.ammo_text_updated.emit(get_ammo_text())
		
		if _interrupt_reload:
			break
	
	_anim.play(&"EndReload")
	anim_name = await _anim.animation_finished
	_reloading = false
	_interrupt_reload = false
	if anim_name != &"EndReload":
		unlock_shooting()
		return
	
	_anim.play(&"PostReload")
	
	tween = create_tween()
	tween.tween_property(self, ^"rotation", _calculate_aim_direction(), to_aim_time)
	await tween.finished
	
	unlock_shooting()


func _create_projectile() -> void:
	for i: int in buckshot_in_shot:
		var projectile: Attack = projectile_scene.instantiate()
		projectile.global_position = _shoot_point.global_position
		projectile.damage_multiplier = _player.damage_multiplier
		projectile.rotation = _player.player_input.aim_direction.angle() + deg_to_rad(
				_calculate_spread() * (-1 + 2.0 / (buckshot_in_shot - 1) * i)
		) + deg_to_rad(_calculate_recoil()) * signf(_player.player_input.aim_direction.x)
		projectile.team = _player.team
		projectile.who = _player.id
		projectile.name += str(randi())
		_projectiles_parent.add_child(projectile)
