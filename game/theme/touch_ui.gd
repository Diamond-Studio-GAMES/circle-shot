extends Node


var _player: Player
@onready var _move_joystick: VirtualJoystick = $MoveVirtualJoystick
@onready var _aim_joystick: VirtualJoystick = $AimVirtualJoystick
@onready var _shoot_area: TouchScreenButton = $ShootArea


func _ready() -> void:
	if not OS.has_feature("mobile"):
		queue_free()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_player.input.direction = _move_joystick.output.normalized()
	if not _aim_joystick.output.is_zero_approx():
		_player.input.aiming_direction = _aim_joystick.output.normalized()
		_player.input.is_aiming = true
	else:
		_player.input.is_aiming = false
		if not is_zero_approx(_move_joystick.output.x):
			_player.input.aiming_direction.x = absf(_player.input.aiming_direction.x) * signf(_move_joystick.output.x)
	_player.input.is_shooting = _shoot_area.is_pressed()


func _on_local_player_created(player: Player) -> void:
	_player = player
