class_name WeaponConfig
extends Resource

enum Type {
	LIGHT = 0,
	HEAVY = 1,
	SUPPORT = 2,
	MELEE = 3,
}

@export var weapon_name: String
@export var weapon_type := Type.LIGHT
@export var rarity := ItemsDB.Rarity.COMMON
@export_group("Stats")
@export var damage_text: String
@export var ammo_text: String
@export_group("Paths")
@export_file("*.tscn") var weapon_path: String
@export_file("*.png") var image_path: String

