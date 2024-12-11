class_name SmartCamera
extends Camera2D


signal shake_finished
signal pan_finished

var target: Node2D
var _shake_tween: Tween
var _pan_tween: Tween


func _ready() -> void:
	position_smoothing_enabled = Globals.get_setting_bool("smooth_camera")


func _process(_delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position


func pan(to: Vector2, duration: float, ease_type := Tween.EASE_OUT,
		trans_type := Tween.TRANS_QUAD, from: Vector2 = global_position) -> void:
	if is_instance_valid(_pan_tween):
		_pan_tween.finished.emit()
		_pan_tween.kill()
	
	_pan_tween = create_tween()
	_pan_tween.set_trans(trans_type).set_ease(ease_type)
	_pan_tween.tween_property(self, ^":position", to, duration).from(from)
	await _pan_tween.finished
	pan_finished.emit()


func pan_to_target(to: Node2D, duration: float, ease_type := Tween.EASE_OUT,
		trans_type := Tween.TRANS_QUAD, from: Vector2 = position) -> void:
	if is_instance_valid(_pan_tween):
		_pan_tween.finished.emit()
		_pan_tween.kill()
	
	target = null
	_pan_tween = create_tween()
	_pan_tween.set_trans(trans_type).set_ease(ease_type)
	_pan_tween.tween_method(_lerp_to.bind(from, to), 0.0, 1.0, duration)
	await _pan_tween.finished
	pan_finished.emit()
	target = to


func shake(amplitude: float, duration: float, should_decay := true, shake_step := 0.05) -> void:
	if is_instance_valid(_shake_tween):
		_shake_tween.finished.emit()
		_shake_tween.kill()
	
	_shake_tween = create_tween()
	var steps := int(duration / shake_step)
	for i: int in steps:
		var random_vector := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var current_amplitude: float = amplitude / steps * (steps - i)
		if not should_decay:
			current_amplitude = amplitude
		_shake_tween.tween_property(self, ^":offset",
				random_vector.normalized() * current_amplitude, shake_step)
	_shake_tween.tween_property(self, ^":offset", Vector2.ZERO, shake_step)
	await _shake_tween.finished
	shake_finished.emit()


func _lerp_to(weight: float, from: Vector2, to: Node2D) -> void:
	position = from.lerp(to.global_position, weight)
