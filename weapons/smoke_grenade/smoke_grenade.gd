extends Weapon


@export var projectile: PackedScene
@export var throw_time: float = 1.0
@export var equip_time: float = 1.0
var _can_throw := true
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _throw_point: Marker2D = $ThrowPoint
@onready var _aim: Node2D = $Aim


func _process(_delta: float) -> void:
	_aim.visible = player.input.is_aiming and _can_use_weapon()
	if _aim.visible:
		var aim_direction: Vector2 = player.input.aiming_direction
		aim_direction.x = absf(aim_direction.x) 
		_aim.rotation = aim_direction.angle()
	if multiplayer.multiplayer_peer:
		if multiplayer.is_server():
			if ammo > 0 and _can_use_weapon() \
					and _can_throw and player.input.is_shooting:
				shoot.rpc()


func _make_current() -> void:
	if ammo > 0 and _can_throw:
		show()
		_anim.play("Equip")
		player.lock_weapon_use(equip_time)
	else:
		hide()


func _shoot() -> void:
	player.lock_weapon_use(throw_time)
	ammo -= 1
	_can_throw = false
	($ThrowTimer as Timer).start()
	_anim.play("Throw")
	var throw_direction: Vector2 = player.input.aiming_direction
	await _anim.animation_finished
	var projectile_node: Node2D = projectile.instantiate()
	projectile_node.global_position = _throw_point.global_position
	projectile_node.rotation = throw_direction.angle()
	projectile_node.name += str(randi())
	_projectiles_parent.add_child(projectile_node)


func get_ammo_text() -> String:
	return "Осталось: %d" % ammo


func _on_throw_timer_timeout() -> void:
	_can_throw = true
	_make_current()
