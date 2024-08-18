extends Node


const SNEAK_MULTIPLIER := 0.4
var _player: Player
var _touch := true
var _moving_left := false
var _moving_right := false
var _moving_up := false
var _moving_down := false
@onready var _move_joystick: VirtualJoystick = $TouchControls/MoveVirtualJoystick
@onready var _aim_joystick: VirtualJoystick = $TouchControls/AimVirtualJoystick
@onready var _shoot_area: TouchScreenButton = $TouchControls/ShootArea


func _ready() -> void:
	if not OS.has_feature("mobile"):
		$TouchControls.hide()
		_touch = false


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	
	if _touch:
		_player.entity_input.direction = _move_joystick.output
		if not _aim_joystick.output.is_zero_approx():
			_player.player_input.aim_direction = _aim_joystick.output
			_player.player_input.aiming = true
		else:
			_player.player_input.aiming = false
		_player.player_input.shooting = _shoot_area.is_pressed()
	else:
		_player.entity_input.direction = (
			Vector2.LEFT * int(_moving_left) + Vector2.RIGHT * int(_moving_right)
			+ Vector2.UP * int(_moving_up) + Vector2.DOWN * int(_moving_down)
		).normalized()
		if Input.is_action_pressed(&"sneak"):
			_player.entity_input.direction *= SNEAK_MULTIPLIER
		
		if _player.player_input.aiming:
			_player.player_input.aim_direction = \
					_player.global_position.direction_to(_player.get_global_mouse_position())


func _unhandled_key_input(event: InputEvent) -> void:
	if not _touch:
		if event.is_action("move_left"):
			_moving_left = event.is_pressed()
		if event.is_action("move_right"):
			_moving_right = event.is_pressed()
		if event.is_action("move_up"):
			_moving_up = event.is_pressed()
		if event.is_action("move_down"):
			_moving_down = event.is_pressed()


func _on_local_player_created(player: Player) -> void:
	_player = player
