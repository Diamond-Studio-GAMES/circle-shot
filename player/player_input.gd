class_name PlayerInput
extends MultiplayerSynchronizer

var direction := Vector2()
var aiming_direction := Vector2.RIGHT
var is_shooting := false
var is_aiming := false
var _is_touch := false

func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		process_mode = PROCESS_MODE_DISABLED
		return
	if OS.has_feature("mobile"):
		_is_touch = true


func _unhandled_input(event: InputEvent) -> void:
	if not _is_touch:
		is_shooting = event.is_action_pressed("shoot")
		is_aiming = event.is_action_pressed("aim")


func _process(_delta: float) -> void:
	if not _is_touch:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
