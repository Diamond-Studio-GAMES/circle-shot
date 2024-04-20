class_name PlayerInput
extends MultiplayerSynchronizer

var direction := Vector2()

func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		process_mode = PROCESS_MODE_DISABLED


func _process(_delta: float) -> void:
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
