extends Effect


func _start_effect() -> void:
	($Smoke as CPUParticles2D).restart()
	var tween: Tween = create_tween()
	var should_be_visible: bool = _entity.is_local()
	var event: Event = get_tree().get_first_node_in_group(&"Event")
	if event:
		should_be_visible = should_be_visible or event.local_team == _entity.team
	if should_be_visible:
		tween.tween_property(_entity.visual, ^":modulate", Color(1.0, 1.0, 1.0, 0.5), 0.5)
	else:
		tween.tween_property(_entity, ^":modulate", Color.TRANSPARENT, 0.5)


func _end_effect() -> void:
	var tween: Tween = _entity.create_tween()
	tween.tween_property(_entity.visual if _entity.is_local() else _entity,
			^":modulate", Color.WHITE, 0.3)
