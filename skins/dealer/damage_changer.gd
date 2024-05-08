extends Node

@export var damaged_texture: Texture2D
@export_node_path("Sprite2D") var sprite_path: NodePath
@onready var _sprite: Sprite2D = get_node(sprite_path)

func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if old_value > new_value:
		_sprite.texture = damaged_texture
