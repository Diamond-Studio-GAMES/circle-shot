extends PlayerSkin

@export var damaged_texture: Texture2D

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if old_value > new_value:
		texture = damaged_texture
