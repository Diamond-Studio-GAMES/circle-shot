extends Node

@export var textures: Array[Texture2D]
@export_node_path("Sprite2D") var sprite_path: NodePath
@onready var _sprite: Sprite2D = get_node(sprite_path)

func _on_player_weapon_changed(type: Weapon.Type) -> void:
	_sprite.texture = textures[type]
