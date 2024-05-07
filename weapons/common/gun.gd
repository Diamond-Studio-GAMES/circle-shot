extends Weapon


@export var equip_time: float = 0.5
@export var reload_time: float = 1.5
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
		rotation = aim_direction.angle()
	_shoot_timer -= delta
	if multiplayer.multiplayer_peer:
		if multiplayer.is_server():
			if player.input.is_shooting and _shoot_timer <= 0.0 \
					and ammo >= ammo_per_shot and _can_use_weapon():
				shoot.rpc()


func _make_current() -> void:
	rotation = 0
	player.lock_weapon_use(equip_time + 0.15)
	_anim.play("Equip")
	await _anim.animation_finished
	var aim_direction: Vector2 = player.input.aiming_direction
	aim_direction.x = absf(aim_direction.x) 
	var tween := create_tween()
	tween.tween_property(self, ^"rotation", aim_direction.angle(), 0.15)


func _shoot() -> void:
	_shoot_timer = shoot_interval
	ammo -= ammo_per_shot
	_anim.play("Shoot")
	_anim.seek(0, true)
	if multiplayer.is_server():
		var projectile_node: Attack = projectile.instantiate()
		projectile_node.global_position = _shoot_point.global_position
		projectile_node.damage = roundi(projectile_node.damage * player.damage_multiplier)
		projectile_node.rotation = player.input.aiming_direction.angle() \
				+ deg_to_rad(randf_range(-spread, spread))
		projectile_node.team = player.team
		projectile_node.who = player.player
		projectile_node.name += str(randi())
		_projectiles_parent.add_child(projectile_node)
	if ammo <= 0:
		await _anim.animation_finished
		_reload()


func _reload() -> void:
	if ammo_total < ammo_per_load:
		return
	var tween := create_tween()
	tween.tween_property(self, ^"rotation", 0.0, 0.15)
	_anim.play("Reload")
	player.lock_weapon_use(reload_time + 0.15)
	await _anim.animation_finished
	var aim_direction: Vector2 = player.input.aiming_direction
	aim_direction.x = absf(aim_direction.x) 
	tween = create_tween()
	tween.tween_property(self, ^"rotation", aim_direction.angle(), 0.15)
	ammo = ammo_per_load
	ammo_total -= ammo_per_load
	player.ammo_text_updated.emit(get_ammo_text())
