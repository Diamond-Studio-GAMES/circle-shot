extends PlayerSkin


func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if old_value > new_value:
		($AnimationPlayer as AnimationPlayer).play(&"TrueSide")
		($AnimationPlayer as AnimationPlayer).seek(0.0, true)
