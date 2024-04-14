class_name ItemsDB
extends Resource

enum Item {
	GAME = 0,
	MAP = 1,
	LIGHT_WEAPON = 2,
	HEAVY_WEAPON = 3,
	SUPPORT_WEAPON = 4,
	MELEE_WEAPON = 5,
	SKIN = 6,
}

@export var games: Array[GameConfig]
