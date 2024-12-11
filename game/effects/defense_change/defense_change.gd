extends Effect


func _start_effect() -> void:
	if _data.size() != 1:
		queue_free()
		return
	var multiplier: float = _data[0]
	if is_zero_approx(multiplier):
		_entity.make_immune()
		# TODO: мб добавить особую анимку
	else:
		_entity.defense_multiplier *= multiplier
	if multiplier > 1.0:
		($Down as CanvasItem).show()
		negative = true
	elif multiplier < 1.0:
		($Bubble/AnimationPlayer as AnimationPlayer).play(&"Shield")


func _end_effect() -> void:
	var multiplier: float = _data[0]
	if is_zero_approx(multiplier):
		_entity.unmake_immune()
	else:
		_entity.defense_multiplier /= multiplier
