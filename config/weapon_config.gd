class_name WeaponConfig
extends Resource

enum Weapon {
	LIGHT = 0,
	HEAVY = 1,
	SUPPORT = 2,
	MELEE = 3,
}
enum Damage {
	PER_SECOND = 0,
	INSTANT = 1,
}

@export var weapon_name := "Desert Eagle"
@export var weapon_type := Weapon.LIGHT
@export var rarity := ItemsDB.Rarity.COMMON
@export_group("Stats")
@export var damage: int
@export var damage_type := Damage.PER_SECOND
@export var ammo_per_charge: int
@export var ammo_total: int
@export_group("Scenes")
@export_file("*.tscn") var weapon_path: String
@export_file("*.png") var image_path: String

