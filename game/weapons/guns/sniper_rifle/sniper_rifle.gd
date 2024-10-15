extends "res://game/weapons/guns/common/gun.gd"


const BLUR_SPREAD_MULTIPLIER := 0.2
@export var aim_slowdown := 0.8
@export var no_aim_spread := 8.0
var _aiming := false
@onready var _aim_ray: RayCast2D = $ShootPoint/AimRay
@onready var _aim_target: Marker2D = $ShootPoint/AimTarget
@onready var _end_aim: Marker2D = $ShootPoint/EndAim
@onready var _aim_texture_material: ShaderMaterial = ($Aim/Base/Aim as Control).material


func _process(delta: float) -> void:
	super(delta)
	if _aiming and _player.is_local():
		_aim_target.global_position = _calculate_aim_target_position()
		_aim_texture_material.set_shader_parameter(&"radius", _calculate_spread() * BLUR_SPREAD_MULTIPLIER)


func _exit_tree() -> void:
	if _aiming:
		end_aim()


func _initialize() -> void:
	super()
	($ShootPoint as Node2D).hide()


func _unmake_current() -> void:
	super()
	if _aiming:
		end_aim()


func reload() -> void:
	if _aiming:
		end_aim()
	super()


func has_additional_button() -> bool:
	return true


func additional_button() -> void:
	if not can_shoot():
		return
	
	if _aiming:
		end_aim()
	else:
		start_aim()


func _calculate_spread() -> float:
	if _aiming:
		return super()
	return super() + no_aim_spread


func start_aim() -> void:
	_aiming = true
	_player.speed_multiplier *= aim_slowdown
	if _player.id != multiplayer.get_unique_id():
		return
	
	_aim_ray.enabled = true
	_aim_ray.force_raycast_update()
	($Aim as CanvasLayer).show()
	($ShootPoint as Node2D).show()
	var camera: SmartCamera = get_viewport().get_camera_2d()
	camera.target = _aim_target
	camera.position_smoothing_enabled = false
	camera.global_position = _calculate_aim_target_position()


func end_aim() -> void:
	_aiming = false
	_player.speed_multiplier /= aim_slowdown
	if _player.id != multiplayer.get_unique_id():
		return
	
	($Aim as CanvasLayer).hide()
	($ShootPoint as Node2D).hide()
	_aim_ray.enabled = false
	
	var camera: SmartCamera = get_viewport().get_camera_2d()
	if not is_instance_valid(camera):
		return
	
	camera.position_smoothing_enabled = true
	if camera.target == _aim_target:
		camera.target = _player
		camera.global_position = camera.target.global_position
		camera.reset_smoothing()


func _calculate_aim_target_position() -> Vector2:
	var ratio: float = (
			_aim_ray.get_collision_point() - _aim_ray.global_position
	).length() / absf(_aim_ray.position.x - _end_aim.position.x) if _aim_ray.is_colliding() else 1.0
	return _aim_ray.global_position.lerp(
			_end_aim.global_position,
			minf(_player.player_input.aim_direction.length(), ratio),
	)
