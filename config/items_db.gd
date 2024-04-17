class_name ItemsDB
extends Resource

enum Item {
	GAME = 0,
	MAP = 1,
	WEAPON_LIGHT = 2,
	WEAPON_HEAVY = 3,
	WEAPON_SUPPORT = 4,
	WEAPON_MELEE = 5,
	SKIN = 6,
}

@export var games: Array[GameConfig]
@export var skins: Array[SkinConfig]
@export_group("Weapons", "weapons_")
@export var weapons_light: Array[WeaponConfig]
@export var weapons_heavy: Array[WeaponConfig]
@export var weapons_support: Array[WeaponConfig]
@export var weapons_melee: Array[WeaponConfig]
