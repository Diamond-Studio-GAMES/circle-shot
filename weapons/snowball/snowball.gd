extends Weapon


@export var equip_time_per_snowball: float = 0.5
@export var reload_time: float = 1.5
@export var throw_time: float = 0.4
@export var shoot_interval: float = 0.5
@export var ammo_per_shot: int = 1
@export var spread: float = 4.0
@export var projectile: PackedScene
var _shoot_timer: float = 0.0
@onready var _shoot_point: Marker2D = $ShootPoint
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _aim: Node2D = $Aim


func _process(delta: float) -> void:
	_aim.visible = player.input.is_aiming and _can_use_weapon()
	if _can_use_weapon():
		var aim_direction: Vector2 = player.input.aiming_direction
		aim_direction.x = absf(aim_direction.x) 
		_aim.rotation = aim_direction.angle()
	_shoot_timer -= delta
	if multiplayer.multiplayer_peer:
		if multiplayer.is_server():
			if player.input.is_shooting and _shoot_timer <= 0.0 \
					and ammo >= ammo_per_shot and _can_use_weapon():
				shoot.rpc()


func _make_current() -> void:
	player.lock_weapon_use(equip_time_per_snowball * ammo + 0.05)
	if ammo > 0:
		_anim.play("Equip0")
		await _anim.animation_finished
	if ammo > 1:
		_anim.play("Equip1")


func _shoot() -> void:
	player.lock_weapon_use(throw_time)
	var throw_direction: Vector2 = player.input.aiming_direction
	_shoot_timer = shoot_interval
	ammo -= ammo_per_shot
	if ammo == 0:
		_anim.play("Throw1")
	else:
		_anim.play("Throw0")
	_anim.seek(0, true)
	await _anim.animation_finished
	if multiplayer.is_server():
		var projectile_node: Attack = projectile.instantiate()
		projectile_node.global_position = _shoot_point.global_position
		projectile_node.damage = roundi(projectile_node.damage * player.damage_multiplier)
		projectile_node.rotation = throw_direction.angle() \
				+ deg_to_rad(randf_range(-spread, spread))
		projectile_node.team = player.team
		projectile_node.who = player.player
		projectile_node.name += str(randi())
		_projectiles_parent.add_child(projectile_node)
	if ammo <= 0:
		_reload()


func _reload() -> void:
	if ammo_total < ammo_per_load:
		return
	_anim.play("Reload")
	player.lock_weapon_use(reload_time)
	await _anim.animation_finished
	ammo = ammo_per_load
	ammo_total -= ammo_per_load
	player.ammo_text_updated.emit(get_ammo_text())
