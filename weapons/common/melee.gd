extends Weapon


@export var shoot_interval: float = 1.0
@export var equip_time: float = 0.65
@export var damage: int
@export var attack_time: float = 0.5
var _shoot_timer: float = 0.0
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _aim: Node2D = $Aim


func _ready() -> void:
	super()
	if multiplayer.is_server():
		($AttackArea as Attack).team = player.team
		($AttackArea as Attack).who = player.player


func _process(delta: float) -> void:
	_aim.visible = player.input.is_aiming and _can_use_weapon()
	if _can_use_weapon():
		var aim_direction: Vector2 = player.input.aiming_direction
		aim_direction.x = absf(aim_direction.x) 
		rotation = aim_direction.angle()
	_shoot_timer -= delta
	if multiplayer.multiplayer_peer:
		if multiplayer.is_server():
			if player.input.is_shooting and _can_use_weapon() and _shoot_timer <= 0.0:
				shoot.rpc()


func _shoot() -> void:
	player.lock_weapon_use(attack_time)
	_shoot_timer = shoot_interval
	_anim.play("Attack")
	_anim.seek(0, true)
	if multiplayer.is_server():
		($AttackArea as Attack).damage = roundi(damage * player.damage_multiplier)


func _make_current() -> void:
	rotation = 0
	player.lock_weapon_use(equip_time)
	_anim.play("Equip")
	await _anim.animation_finished
	var aim_direction: Vector2 = player.input.aiming_direction
	aim_direction.x = absf(aim_direction.x) 
	var tween := create_tween()
	tween.tween_property(self, "rotation", aim_direction.angle(), 0.15)


func get_ammo_text() -> String:
	return "Неограниченно"
