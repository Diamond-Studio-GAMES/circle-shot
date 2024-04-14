class_name PlayerInput
extends MultiplayerSynchronizer


@export var direction := Vector2.ZERO


func _ready() -> void:
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())


func process(_delta: float) -> void:
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
