extends Weapon

@export var projectile: PackedScene
@export var equip_time: float = 0.5
@export var reload_time: float = 1.5
@export var shoot_interval: float = 0.5
@export var ammo_per_shot: int = 1
var _shoot_timer: float = 0.0
@onready var _shoot_point: Marker2D = $ShootPoint
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _aim: Node2D = $Aim


func _process(delta: float) -> void:
	_aim.visible = player.input.is_aiming and _can_use_weapon()
	if _aim.visible:
		var aim_direction: Vector2 = player.input.aiming_direction
		aim_direction.x = absf(aim_direction.x) 
		rotation = aim_direction.angle()
	_shoot_timer -= delta
	if multiplayer.is_server():
		if player.input.is_shooting and _shoot_timer <= 0.0 \
				and ammo >= ammo_per_shot and _can_use_weapon():
			shoot()


func _make_current() -> void:
	player.lock_weapon_use(equip_time)
	_anim.play("Equip")


func _shoot() -> void:
	_shoot_timer = shoot_interval
	ammo -= ammo_per_shot
	_anim.play("Shoot")
	_anim.seek(0, true)
	if ammo <= 0:
		await _anim.animation_finished
		_reload()


func _reload() -> void:
	var past_rotation := rotation
	var tween := create_tween()
	tween.tween_property(self, "rotation", 0.0, 0.3)
	_anim.play("Reload")
	player.lock_weapon_use(reload_time)
	await _anim.animation_finished
	tween = create_tween()
	tween.tween_property(self, "rotation", past_rotation, 0.3)
