extends Weapon


const NO_SPREAD_WALK_RATIO := 0.5

@export var shoot_interval: float = 0.5
@export var ammo_per_shot: int = 1
@export var to_aim_time := 0.15
@export var projectile_scene: PackedScene

@export_group("Spread", "spread_")
@export var spread_curve: Curve
@export var spread_curve_time := 2.0
@export var spread_base := 1.0
@export var spread_reset_time := 0.3
@export var spread_walk := 1.0
@export var spread_walk_reset_time := 0.5

@export_group("Recoil", "recoil_")
@export var recoil_curve: Curve
@export var recoil_curve_time := 5.0
@export var recoil_reset_time := 0.3

var _shoot_timer := 0.0
var _shooting_time := 0.0

var _spread_reset := 0.0
var _spread_walk_reset := 0.0
var _recoil_reset := 0.0
var _spread_reset_tween: Tween
var _spread_walk_tween: Tween
var _recoil_reset_tween: Tween

@onready var _shoot_point: Marker2D = $ShootPoint
@onready var _anim: AnimationPlayer = $AnimationPlayer

@onready var _aim: Line2D = $ShootPoint/Aim
@onready var _aim_spread_left: Line2D = $ShootPoint/Aim/SpreadLeft
@onready var _aim_spread_right: Line2D = $ShootPoint/Aim/SpreadRight


func _process(delta: float) -> void:
	var shooting_time_increased := false
	_aim.hide()
	
	if not _player.is_disarmed() and can_shoot():
		_aim.visible = _player.player_input.aiming and multiplayer.get_unique_id() == _player.id 
		rotation = _calculate_aim_direction() + deg_to_rad(_calculate_recoil())
		
		_aim_spread_left.rotation_degrees = -_calculate_spread()
		_aim_spread_right.rotation_degrees = _calculate_spread()
		
		if _player.player_input.shooting:
			if ammo >= ammo_per_shot:
				if multiplayer.is_server() and _shoot_timer <= 0.0:
					shoot.rpc()
				_shooting_time += delta
				shooting_time_increased = true
	
	_shoot_timer -= delta
	if not shooting_time_increased:
		if _shooting_time > 0.01:
			if is_instance_valid(_recoil_reset_tween):
				_recoil_reset_tween.kill()
			_recoil_reset_tween = create_tween()
			_recoil_reset = _calculate_recoil()
			_recoil_reset_tween.tween_property(self, ^"_recoil_reset", 0.0, recoil_reset_time)
			
			if is_instance_valid(_spread_reset_tween):
				_spread_reset_tween.kill()
			_spread_reset_tween = create_tween()
			_spread_reset = _calculate_shoot_spread()
			_spread_reset_tween.tween_property(
					self, ^"_spread_reset", spread_base, spread_reset_time
			)
		_shooting_time = 0.0


func _initialize() -> void:
	recoil_curve.bake()
	spread_curve.bake()
	_spread_reset = spread_base


func _make_current() -> void:
	rotation = 0.0
	_anim.play(&"Equip")
	block_shooting()
	
	var anim_name: StringName = await _anim.animation_finished
	if anim_name != &"Equip":
		unlock_shooting()
		return
	
	_anim.play(&"PostEquip")
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"rotation", _calculate_aim_direction(), to_aim_time)
	await tween.finished
	unlock_shooting()
	
	if ammo <= 0:
		reload()


func _unmake_current() -> void:
	_anim.play(&"RESET")
	_anim.advance(0.01)


func _shoot() -> void:
	_shoot_timer = shoot_interval
	ammo -= ammo_per_shot
	_anim.play("Shoot")
	_anim.seek(0, true)
	if multiplayer.is_server():
		_create_projectile()
	if ammo <= 0:
		await _anim.animation_finished
		reload()


func can_reload() -> bool:
	return super() and _shoot_timer <= 0.0


func reload() -> void:
	if ammo_in_stock < ammo_per_load:
		return
	
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"rotation", 0.0, to_aim_time)
	_anim.play(&"Reload")
	block_shooting()
	
	var anim_name: StringName = await _anim.animation_finished
	if anim_name != &"Reload":
		unlock_shooting()
		return
	
	_anim.play(&"PostReload")
	tween = create_tween()
	tween.tween_property(self, ^"rotation", _calculate_aim_direction(), to_aim_time)
	
	ammo = ammo_per_load
	ammo_in_stock -= ammo_per_load
	_player.ammo_text_updated.emit(get_ammo_text())
	
	await tween.finished
	unlock_shooting()


func _calculate_recoil() -> float:
	if _shooting_time > 0.01:
		var recoil_from_curve: float = \
				recoil_curve.sample_baked(minf(_shooting_time / recoil_curve_time, 1.0))
		
		return maxf(absf(recoil_from_curve), absf(_recoil_reset)) * (
				signf(recoil_from_curve) if absf(recoil_from_curve) > absf(_recoil_reset)
				else signf(_recoil_reset)
		)
	
	return _recoil_reset


func _calculate_shoot_spread() -> float:
	if _shooting_time > 0.01:
		return maxf(spread_curve.sample_baked(minf(_shooting_time / spread_curve_time, 1.0)) + \
				spread_base, _spread_reset)
	return _spread_reset


func _calculate_walk_spread() -> float:
	return maxf(_spread_walk_reset, spread_walk * \
			clampf(_player.entity_input.direction.length() - NO_SPREAD_WALK_RATIO, 0.0, 1.0))


func _calculate_spread() -> float:
	return _calculate_walk_spread() + _calculate_shoot_spread()


func _create_projectile() -> void:
	var projectile: Attack = projectile_scene.instantiate()
	projectile.global_position = _shoot_point.global_position
	projectile.damage = roundi(projectile.damage * _player.damage_multiplier)
	var spread: float = _calculate_spread()
	projectile.rotation = _player.player_input.aim_direction.angle() \
			+ deg_to_rad(randf_range(-spread, spread)) \
			+ deg_to_rad(_calculate_recoil()) * signf(_player.entity_input.direction.x)
	projectile.team = _player.team
	projectile.who = _player.id
	projectile.name += str(randi())
	_projectiles_parent.add_child(projectile)
