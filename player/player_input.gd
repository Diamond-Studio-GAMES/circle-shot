extends MultiplayerSynchronizer


@export var direction := Vector2.ZERO


func _physics_process(_delta: float) -> void:
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
