extends Skill


@export var roll_speed := 1280.0
@export var roll_duration := 0.5

var _last_movement_direction := Vector2.RIGHT
@onready var _roll_timer: Timer = $Timer


func _physics_process(delta: float) -> void:
	super(delta)
	if not _player.entity_input.direction.is_zero_approx():
		_last_movement_direction = _player.entity_input.direction.normalized()


func _use() -> void:
	_player.make_disarmed()
	_player.make_immobile()
	_player.knockback = _last_movement_direction * roll_speed
	var previous_collision_layer: int = _player.collision_layer
	_player.collision_layer = 0
	
	var tween: Tween = create_tween()
	tween.tween_property(_player.visual, ^"rotation", TAU, roll_duration)
	tween.tween_callback(func() -> void: _player.visual.rotation = 0.0)
	
	_roll_timer.start(roll_duration)
	await _roll_timer.timeout
	
	_player.unmake_disarmed()
	_player.unmake_immobile()
	_player.knockback = Vector2.ZERO
	_player.collision_layer = previous_collision_layer
