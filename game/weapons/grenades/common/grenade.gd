extends Weapon


@export var projectile_scene: PackedScene
@export var spread_base := 1.0
@export var spread_walk := 5.0
@export_range(0.0, 1.0) var spread_walk_ratio := 0.5
@export var projectile_speed := 800.0
@export var projectile_damping := 200.0
@export var projectile_explosion_time := 2.5

var _reloading := false

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _throw_point: Marker2D = $ThrowPivot/ThrowPoint
@onready var _throw_pivot: Marker2D = $ThrowPivot

@onready var _aim: Line2D = $ThrowPivot/ThrowPoint/Aim
@onready var _aim_spread_left: Line2D = $ThrowPivot/ThrowPoint/Aim/SpreadLeft
@onready var _aim_spread_right: Line2D = $ThrowPivot/ThrowPoint/Aim/SpreadRight


func _process(_delta: float) -> void:
	_aim.hide()
	
	if can_shoot():
		_aim.visible = _player.player_input.showing_aim
		_throw_pivot.rotation = _calculate_aim_direction()
		
		_aim_spread_left.rotation_degrees = -_calculate_spread()
		_aim_spread_right.rotation_degrees = _calculate_spread()
		
		# Вычисление длины пути гранаты через формулу по физике xD
		var speed_multiplier: float = _player.player_input.aim_direction.length()
		var time: float = minf(projectile_speed * speed_multiplier / projectile_damping, \
				projectile_explosion_time)
		_aim.points[1].x = projectile_speed * time * speed_multiplier - \
				projectile_damping / 2 * time * time
		
		if _player.player_input.shooting:
			if ammo_in_stock > 0:
				if multiplayer.is_server() and not _reloading:
					shoot.rpc()


func _make_current() -> void:
	if ammo_in_stock > 0 and not _reloading:
		show()
		_anim.play(&"Equip")
		block_shooting()
		await _anim.animation_finished
		unlock_shooting()
	else:
		hide()


func _unmake_current() -> void:
	_anim.play(&"RESET")
	_anim.advance(0.01)


func _shoot() -> void:
	block_shooting()
	_anim.play(&"Throw")
	var throw_direction: Vector2 = _player.player_input.aim_direction
	var anim_name: StringName = await _anim.animation_finished
	if anim_name != &"Throw":
		unlock_shooting()
		return
	
	var animation: Animation = _anim.get_animation(&"PostThrow")
	animation.track_set_key_value(0, 0, _throw_pivot.position)
	animation.track_set_key_value(0, 1, to_local(_throw_point.global_position))
	_anim.play(&"PostThrow")
	anim_name = await _anim.animation_finished
	if anim_name != &"PostThrow":
		unlock_shooting()
		return
	
	ammo_in_stock -= 1
	_player.ammo_text_updated.emit(get_ammo_text())
	_reloading = true
	($ThrowTimer as Timer).start()
	
	if multiplayer.is_server():
		var projectile: GrenadeProjectile = projectile_scene.instantiate()
		projectile.global_position = _throw_point.global_position
		var spread: float = deg_to_rad(_calculate_spread())
		projectile.direction = throw_direction.rotated(randf_range(-spread, spread))
		projectile.speed *= minf(throw_direction.length(), 1.0)
		_customize_projectile(projectile)
		projectile.name += str(randi())
		_projectiles_parent.add_child(projectile)


func get_ammo_text() -> String:
	return "Осталось: %d" % ammo_in_stock


func can_reload() -> bool:
	return false


func _calculate_spread() -> float:
	return spread_walk * clampf((_player.entity_input.direction.length() - spread_walk_ratio) \
			/ (1.0 - spread_walk_ratio), 0.0, 1.0) + spread_base


func _customize_projectile(_projectile: GrenadeProjectile) -> void:
	pass


func _on_throw_timer_timeout() -> void:
	_reloading = false
	unlock_shooting()
	_make_current()
