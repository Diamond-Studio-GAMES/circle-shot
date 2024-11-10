extends Player


func _ready() -> void:
	super()
	make_immune()
	visual.modulate = Color(1.0, 1.0, 1.0, 0.5)


func _on_immune_timer_timeout() -> void:
	unmake_immune()
	var tween: Tween = create_tween()
	tween.tween_property(visual, ^":modulate", Color.WHITE, 0.3)
