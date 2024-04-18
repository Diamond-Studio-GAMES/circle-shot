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
enum Rarity {
	COMMON = 0,
	RARE = 1,
	EPIC = 2,
	LEGENDARY = 3,
	SECRET = 4,
}
const RARITY_COLORS := {
	Rarity.COMMON: Color(0.675, 1, 1),
	Rarity.RARE: Color(0, 0.9, 0.225),
	Rarity.EPIC: Color(0.625, 0, 0.825),
	Rarity.LEGENDARY: Color(1, 0.93, 0.195),
	Rarity.SECRET: Color(0.415, 0.415, 0.415),
}
@export var games: Array[GameConfig]
@export var skins: Array[SkinConfig]
@export_group("Weapons", "weapons_")
@export var weapons_light: Array[WeaponConfig]
@export var weapons_heavy: Array[WeaponConfig]
@export var weapons_support: Array[WeaponConfig]
@export var weapons_melee: Array[WeaponConfig]
