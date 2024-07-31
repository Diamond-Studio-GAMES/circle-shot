class_name PlayerInput
extends MultiplayerSynchronizer


var direction := Vector2()
var aiming_direction := Vector2.RIGHT
var is_shooting := false
var is_aiming := false
var _is_touch := false
var _moving_left := false
var _moving_right := false
var _moving_up := false
var _moving_down := false
var _player: Node2D


func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		process_mode = PROCESS_MODE_DISABLED
		return
	if OS.has_feature("mobile"):
		_is_touch = true
	if not _is_touch:
		_player = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_touch:
		if event.is_action("aim"):
			is_aiming = event.is_pressed()
			# Обновить чтобы избежать задержки прицела
			aiming_direction = _player.global_position.direction_to(_player.get_global_mouse_position())
		elif event.is_action("shoot"):
			is_shooting = event.is_pressed()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_touch:
		if event.is_action("move_left"):
			_moving_left = event.is_pressed()
		if event.is_action("move_right"):
			_moving_right = event.is_pressed()
		if event.is_action("move_up"):
			_moving_up = event.is_pressed()
		if event.is_action("move_down"):
			_moving_down = event.is_pressed()


func _process(_delta: float) -> void:
	if not _is_touch:
		direction = (
			Vector2.LEFT * int(_moving_left) + Vector2.RIGHT * int(_moving_right)
			+ Vector2.UP * int(_moving_up) + Vector2.DOWN * int(_moving_down)
		).normalized()
		if is_aiming:
			aiming_direction = _player.global_position.direction_to(_player.get_global_mouse_position())
		elif not is_zero_approx(direction.x):
			aiming_direction.x = absf(aiming_direction.x) * signf(direction.x)
