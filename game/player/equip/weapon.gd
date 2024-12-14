class_name Weapon
extends Node2D

## Родительский класс всех оружий в игре.

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
	## Неверный тип оружия.
	INVALID = -1,
}
## Количество боеприпасов в одном магазине.
@export var ammo_per_load: int = 10
## Общее количество боеприпасов.
@export var ammo_total: int = 100
## Множитель скорости игрока, когда это оружие является текущим.
@export_range(0.5, 2.0, 0.01) var speed_multiplier_when_current := 1.0
## Если равно [code]true[/code], выстрел будет произведён при отпускании джойстика прицеливания.
## Иначе стрельба будет весьтись до отпускания джойстика.
@export var shoot_on_joystick_release := false
## Количество боеприпасов в текущем магазине.
var ammo: int
## Количество боеприпасов в запасе.
var ammo_in_stock: int
## Данные оружия.
var data: WeaponData
var _blocked_shooting_counter: int = 0
## Ссылка на игрока.
var _player: Player
@warning_ignore("unused_private_class_variable") # Для дочерних классов
@onready var _projectiles_parent: Node2D = get_tree().get_first_node_in_group(&"ProjectilesParent")


func _ready() -> void:
	ammo = ammo_per_load
	ammo_in_stock = ammo_total - ammo_per_load


## Производит выстрел.[br]
## [b]Примечание[/b]: этот метод должен вызываться только сервером и только как RPC.
@rpc("call_local", "reliable", "authority", 5)
func shoot() -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	_shoot()
	_player.ammo_text_updated.emit(get_ammo_text())


## Инициализирует оружие игроком [param player] и данными [param weapon_data].
func initialize(player: Player, weapon_data: WeaponData) -> void:
	_player = player
	data = weapon_data
	hide()
	process_mode = PROCESS_MODE_DISABLED
	_initialize()


## Делает оружие текущим.
func make_current() -> void:
	show()
	process_mode = PROCESS_MODE_INHERIT
	_player.speed_multiplier *= speed_multiplier_when_current
	_make_current()


## Убирает оружие.
func unmake_current() -> void:
	_unmake_current()
	hide()
	process_mode = PROCESS_MODE_DISABLED
	_player.speed_multiplier /= speed_multiplier_when_current


## Блокирует стрельбу.
func block_shooting() -> void:
	_blocked_shooting_counter += 1


## Разблокирует стрельбу.
func unlock_shooting() -> void:
	_blocked_shooting_counter -= 1


## Возвращает [code]true[/code], если оружие может стрелять.
func can_shoot() -> bool:
	return _blocked_shooting_counter <= 0 and not _player.is_disarmed()


## Метод для переопределения. Перезаряжает оружие. Вызывается объектом игрока.
func reload() -> void:
	pass


## Возвращает [code]true[/code], если оружие можно перезарядить.
func can_reload() -> bool:
	return _can_reload() and ammo != ammo_per_load and ammo_in_stock > 0 and can_shoot()


## Метод для переопределения. Дополнительная кнопка оружия. Вызывается объектом игрока.
func additional_button() -> void:
	pass


## Метод для переопределения. Возвращает [code]true[/code], если оружие имеет дополнительную кнопку.
func has_additional_button() -> bool:
	return false


## Возвращает [code]true[/code], если оружие может использовать дополнительную кнопку.
func can_use_additional_button() -> bool:
	return has_additional_button() and can_shoot() and _can_use_additional_button()


## Возвращает строку с данными о боеприпасах. Можно переопределить.
func get_ammo_text() -> String:
	if ammo + ammo_in_stock <= 0:
		return "Нет патронов"
	return "%d/%d" % [ammo, ammo_in_stock]


func _calculate_aim_angle() -> float:
	var aim_direction: Vector2 = _player.player_input.aim_direction
	aim_direction.x = absf(aim_direction.x)
	return aim_direction.angle()


## Метод для переопределения. Вызывается в момент инициализации.
func _initialize() -> void:
	pass


## Метод для переопределения. Расположите логику стрельбы здесь.
## Создавайте снаряды только на сервере.
func _shoot() -> void:
	pass


## Метод для переопределения. Вызывается, когда оружие становится текущим.
func _make_current() -> void:
	pass


## Метод для переопределения. Вызывается, когда оружие убирается в инвентарь.
func _unmake_current() -> void:
	pass


## Метод для переопределения. Должен возвращать [code]true[/code], если оружие можно
## перезарядить. Сюда можно добавлять условия для этого.
func _can_reload() -> bool:
	return true


## Метод для переопределения. Должен возвращать [code]true[/code], если можно использовать
## дополнительную кнопку оружия. Сюда можно добавлять условия для этого.
func _can_use_additional_button() -> bool:
	return true
