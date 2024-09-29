extends Effect


func _start_effect() -> void:
	($Smoke as GPUParticles2D).restart()
	var tween: Tween = create_tween()
	if multiplayer.get_unique_id() == _entity.id:
		tween.tween_property(
				_entity,
				^"visual:modulate", 
				Color(1.0, 1.0, 1.0, 0.5),
				0.5
		)
	else:
		tween.tween_property(
				_entity,
				^":modulate", 
				Color.TRANSPARENT,
				0.5
		)


func _end_effect() -> void:
	var tween: Tween = _entity.create_tween()
	tween.tween_property(
			_entity,
			^"visual:modulate" if multiplayer.get_unique_id() == _entity.id else ^":modulate", 
			Color.WHITE,
			0.3
	)
