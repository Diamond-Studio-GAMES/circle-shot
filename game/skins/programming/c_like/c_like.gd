extends PlayerSkin

@export var textures: Array[Texture2D]

func _ready() -> void:
	player.weapon_changed.connect(_on_player_weapon_changed)
	player.health_changed.connect(_on_player_health_changed)


func _on_player_weapon_changed(type: Weapon.Type) -> void:
	texture = textures[type]


func _on_player_health_changed(old: int, new: int) -> void:
	if old > new:
		($AnimationPlayer as AnimationPlayer).play(&"Hurt")
		($AnimationPlayer as AnimationPlayer).seek(0.0, true)
