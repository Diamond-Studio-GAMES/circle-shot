class_name ItemsDB
extends Resource

## База данных всех предметов в игре.
##
## Хранит в себе всю информацию обо всех предметах в игре.

## Перечисление предметов в игре.
enum Item {
	## Событие.
	EVENT = 0,
	## Карта события.
	MAP = 1,
	## Скин.
	SKIN = 2,
	## Лёгкое оружие.
	WEAPON_LIGHT = 3,
	## Тяжёлое оружие.
	WEAPON_HEAVY = 4,
	## Оружие поддержки.
	WEAPON_SUPPORT = 5,
	## Ближнее оружие.
	WEAPON_MELEE = 6,
	## Навык.
	SKILL = 7,
}
## Редкость некоторых предметов.
enum Rarity {
	## Обычная редкость (не надо разблокировать).
	COMMON = 0,
	## Редкая редкость (хах).
	RARE = 1,
	## Эпическая редкость.
	EPIC = 2,
	## Легендарная редкость.
	LEGENDARY = 3,
	## СЕКРЕТНАЯ редкость (нельзя просмотреть предметы до разблокировки).
	SECRET = 4,
	## Особая редкость (нельзя получить из ящиков).
	SPECIAL = 5,
}

## Цвета редкостей.
const RARITY_COLORS: Dictionary[Rarity, Color] = {
	Rarity.COMMON: Color(0.675, 1, 1),
	Rarity.RARE: Color(0, 0.9, 0.225),
	Rarity.EPIC: Color(0.625, 0, 0.825),
	Rarity.LEGENDARY: Color(1, 0.93, 0.195),
	Rarity.SECRET: Color(0.415, 0.415, 0.415),
	Rarity.SPECIAL: Color(1, 0.492, 0),
}
## Массив событий.
@export var events: Array[EventData]
@export_group("Equip")
## Массив скинов.
@export var skins: Array[SkinData]
## Массив лёгких оружий.
@export var weapons_light: Array[WeaponData]
## Массив тяжёлых оружий.
@export var weapons_heavy: Array[WeaponData]
## Массив оружий поддержки.
@export var weapons_support: Array[WeaponData]
## Массив ближних оружий.
@export var weapons_melee: Array[WeaponData]
## Массив навыков.
@export var skills: Array[SkillData]
## Массив из путей к сценам, которые должны синхронизироваться при появлении, связанных с оружием. 
## Автоматически создаётся из [member WeaponData.spawnable_scenes_paths] у всех оружий.
var spawnable_projectiles_paths: Array[String]
## Массив из путей к сценам, которые должны синхронизироваться при появлении, не связанных
## с оружием. Автоматически создаётся из [member SkillData.spawnable_scenes_paths] у всех навыков.
var spawnable_other_paths: Array[String]


## Инициализирует базу данных предметов.
func initialize() -> void:
	spawnable_projectiles_paths.clear()
	spawnable_other_paths.clear()
	
	for i: WeaponData in weapons_light:
		spawnable_projectiles_paths.append_array(i.spawnable_scenes_paths)
	for i: WeaponData in weapons_heavy:
		spawnable_projectiles_paths.append_array(i.spawnable_scenes_paths)
	for i: WeaponData in weapons_support:
		spawnable_projectiles_paths.append_array(i.spawnable_scenes_paths)
	for i: WeaponData in weapons_melee:
		spawnable_projectiles_paths.append_array(i.spawnable_scenes_paths)
	
	for i: SkillData in skills:
		spawnable_other_paths.append_array(i.spawnable_scenes_paths)
	
	# Задавание idx_in_db у предметов.
	for i: int in range(skins.size()):
		skins[i].idx_in_db = i
	for i: int in range(skills.size()):
		skills[i].idx_in_db = i
	for i: int in range(weapons_light.size()):
		weapons_light[i].idx_in_db = i
	for i: int in range(weapons_heavy.size()):
		weapons_heavy[i].idx_in_db = i
	for i: int in range(weapons_support.size()):
		weapons_support[i].idx_in_db = i
	for i: int in range(weapons_melee.size()):
		weapons_melee[i].idx_in_db = i
