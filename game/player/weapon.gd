class_name Weapon
extends Node2D


## Тип оружия. Игрок может носить только 1 оружие каждого типа.
enum Type {
	## Лёгкое оружие, чаще всего пистолеты. Мобильные и быстро перезаряжаются.
	LIGHT = 0,
	## Тяжёлое оружие. Наносит много урона, но менее мобильное и дольше перезаряжается.
	HEAVY = 1,
	## Оружие поддержки. Не является основным источником урона, а помогает его наносить.
	SUPPORT = 2,
	## Ближнее оружие. Чаще всего имеет неограниченное количество боеприпасов.
	MELEE = 3,
}
@export var ammo_per_load: int = 10
@export var ammo_total: int = 150
@export var speed_multiplier_when_current := 1.0
var ammo: int
var ammo_in_stock: int
var _blocked_shooting_counter: int = 0
var _player: Player
@warning_ignore("unused_private_class_variable") # Для дочерних классов
@onready var _projectiles_parent: Node2D = get_tree().get_first_node_in_group("ProjectilesParent")


func _ready() -> void:
	ammo = ammo_per_load
	ammo_in_stock = ammo_total - ammo_per_load


@rpc("call_local", "reliable", "authority", 2)
func shoot() -> void:
	_shoot()
	_player.ammo_text_updated.emit(get_ammo_text())


func initialize(player: Player) -> void:
	_player = player
	hide()
	process_mode = PROCESS_MODE_DISABLED
	_initialize()


func make_current() -> void:
	show()
	process_mode = PROCESS_MODE_INHERIT
	_player.speed_multiplier *= speed_multiplier_when_current
	_make_current()


func unmake_current() -> void:
	_unmake_current()
	hide()
	process_mode = PROCESS_MODE_DISABLED
	_player.speed_multiplier /= speed_multiplier_when_current


func block_shooting() -> void:
	_blocked_shooting_counter += 1


func unlock_shooting() -> void:
	_blocked_shooting_counter -= 1


func can_shoot() -> bool:
	return _blocked_shooting_counter <= 0


func reload() -> void:
	pass


func can_reload() -> bool:
	return ammo != ammo_per_load and (ammo_in_stock > 0 or ammo > 0)


func additional_button() -> void:
	pass


func has_additional_button() -> bool:
	return false


func get_ammo_text() -> String:
	if ammo + ammo_in_stock <= 0:
		return "Нет патронов"
	return "%d/%d" % [ammo, ammo_in_stock]


func _calculate_aim_direction() -> float:
	var aim_direction: Vector2 = _player.player_input.aim_direction
	aim_direction.x = absf(aim_direction.x)
	return aim_direction.angle()


func _initialize() -> void:
	pass


func _shoot() -> void:
	pass


func _make_current() -> void:
	pass


func _unmake_current() -> void:
	pass
