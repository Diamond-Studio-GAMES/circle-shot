extends Effect

@export var shake_amplitude := 8.0
@export var shake_speed := 0.3
var _shake_tween: Tween

func _start_effect() -> void:
	_entity.make_immobile()
	_entity.make_disarmed()
	_shake_tween = create_tween()
	_shake_tween.set_loops()
	_shake_tween.tween_property(_entity.visual, ^"position:x", shake_amplitude, shake_speed)
	_shake_tween.tween_property(_entity.visual, ^"position:x", -shake_amplitude, shake_speed)


func _end_effect() -> void:
	_shake_tween.kill()
	var tween: Tween = _entity.create_tween()
	tween.tween_property(_entity.visual, ^"position:x", 0.0, shake_speed)
	_entity.unmake_immobile()
	_entity.unmake_disarmed()
