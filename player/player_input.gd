class_name PlayerInput
extends MultiplayerSynchronizer

var direction := Vector2()
var aiming_direction := Vector2.RIGHT
var is_shooting := false
var is_aiming := false
var _is_touch := false
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
		if event.is_action("shoot"):
			is_shooting = event.is_pressed()
		if event.is_action("aim"):
			is_aiming = event.is_pressed()


func _process(_delta: float) -> void:
	if not _is_touch:
		aiming_direction = _player.global_position.direction_to(_player.get_global_mouse_position())
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
