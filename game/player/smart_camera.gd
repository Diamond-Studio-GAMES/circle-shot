class_name SmartCamera
extends Camera2D

var target: Node2D
var _shake_tween: Tween

func _ready() -> void:
	position_smoothing_enabled = Globals.get_setting_bool("smooth_camera")


func _process(_delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position


func shake(amplitude: float, duration: float, should_decay := true, shake_step := 0.05) -> void:
	if is_instance_valid(_shake_tween):
		_shake_tween.kill()
	
	_shake_tween = create_tween()
	var steps := int(duration / shake_step)
	for i: int in steps:
		var random_vector := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var current_amplitude: float = amplitude / steps * (steps - i)
		if not should_decay:
			current_amplitude = amplitude
		_shake_tween.tween_property(
				self, ^"offset", random_vector.normalized() * current_amplitude, shake_step
		)
	_shake_tween.tween_property(self, ^"offset", Vector2.ZERO, shake_step)
