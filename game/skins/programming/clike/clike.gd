extends PlayerSkin

@export var textures: Array[Texture2D]

func _ready() -> void:
	player.weapon_changed.connect(_on_player_weapon_changed)


func _on_player_weapon_changed(type: Weapon.Type) -> void:
	texture = textures[type]
