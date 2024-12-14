class_name Entity
extends CharacterBody2D

## Основной узел сущности.
##
## Сущность имеет здоровье, команду, идентификатори ещё некоторые свойства.
## Именно от этого класса наследуется [Player].

## Издаётся, когда сущность меняет своё здоровье. В аргументах есть старое и новое здоровье.
signal health_changed(old_value: int, new_value: int)
## Издаётся при получении урона. [param by] содержит ID сущности, нанёсшей урон,
## а [param who] содержит ID сущности, получившей урон (то есть этой).[br]
## [b]Примечание[/b]: этот сигнал издаётся только на сервере.
signal damaged(who: int, by: int)
## Издаётся при смерти. [param by] содержит ID сущности, совершившей убийство,
## а [param who] содержит ID умершей сущности (то есть этой).[br]
## [b]Примечание[/b]: этот сигнал издаётся только на сервере.
signal killed(who: int, by: int)
## Издаётся при смерти. [param who] содержит ID умершей сущности (то есть этой).
signal died(who: int)

## Цвета команд.
const TEAM_COLORS: Array[Color] = [
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.ORANGE,
	Color.CYAN,
	Color.BLUE_VIOLET,
	Color.GRAY,
	Color.SADDLE_BROWN,
	Color.HOT_PINK,
]

## Базовая скорость сущности.
@export var speed := 640.0
## Максимальное здоровье сущности.
@export var max_health: int = 100
## Ипользуется при интерполяции движения сущности на клиентах.
## @deprecated: интерполяция движения будет переработана в будущем.
@export var magic := 1600.0
## Визуальный эффект получения урона. Не прикрепляется к сущности и должен самоуничтожаться.
@export var hurt_vfx_scene: PackedScene
## Визуальный эффект смерти. Не прикрепляется к сущности и должен самоуничтожаться.
@export var death_vfx_scene: PackedScene
## Визуальный эффект получения лечения. Не прикрепляется к сущности и должен самоуничтожаться.
@export var heal_vfx_scene: PackedScene

## ID сущности. Автоматически вызывает [method Node.set_multiplayer_authority] с этим ID
## на узле типа [EntityInput].
var id: int = -1:
	set(value):
		id = value
		$Input.set_multiplayer_authority(value if id > 0 else MultiplayerPeer.TARGET_PEER_SERVER)
## Текущее здоровье сущности.
var current_health: int
## Команда сущности. Сущности из одной команды не могут наносить урон друг другу.
var team: int = 0
## Множитель скорости. НЕ устанавливайте на 0, используйте [method make_immobile] вместо этого.
var speed_multiplier := 1.0
## Множитель исходящего урона. НЕ устанавливайте на 0, используйте
## [method make_disarmed] вместо этого.
var damage_multiplier := 1.0
## Множитель исходящего урона. Чем он выше, тем больше урона сущность получает. НЕ устанавливайте
## на 0, используйте [method make_immune] вместо этого.
var defense_multiplier := 1.0
## Вектор отбрасывания. Всегда добавляется к результируещему движению сущности.
var knockback := Vector2.ZERO
## Позиция сущности на сервере. Ипользуется при интерполяции движения сущности на клиентах.
## @deprecated: интерполяция движения будет переработана в будущем.
var server_position: Vector2

var _immune_counter: int = 0
var _immobile_counter: int = 0
var _disarmed_counter: int = 0
var _numbers_vfx_scene: PackedScene

## Узел, содержащий ввод сущности.
@onready var entity_input: EntityInput = $Input
## Родительский узел визуальной составляещей сущности.
@onready var visual: Node2D = $Visual
@onready var _effects: Node2D = $Effects
@onready var _vfx_parent: Node2D = get_tree().get_first_node_in_group(&"VfxParent")


func _ready() -> void:
	current_health = max_health
	server_position = position
	
	if Globals.get_setting_bool("show_damage"):
		_numbers_vfx_scene = load("uid://dxiacndmn0qr7")


func _physics_process(delta: float) -> void:
	velocity = knockback
	var self_velocity := Vector2.ZERO
	if not is_immobile():
		self_velocity = entity_input.direction.limit_length(1.0) * speed * speed_multiplier
	velocity += self_velocity
	move_and_slide()
	# TODO: сделать что нибудь с этим
	if multiplayer.is_server():
		server_position = position
	else:
		position = position.lerp(server_position,
				clampf(position.distance_to(server_position) / magic * delta, 0.0, 1.0))
	
	if not is_zero_approx(self_velocity.x):
		visual.scale.x = -1 if self_velocity.x < 0 else 1


#region Методы эффектов
## Добавляет эффект на сущность. В [param effect_id] должна быть передана одна из констант
## класса [Effect] с UID нужного эффекта. В [param duration] можно передать длительность эффекта, а
## в [param data] могут быть переданы данные для эффекта (если требуются).
## [param should_stack] может отключить возможность стакаться эффекту
## (если она уже не была отключена с помощью [member Effect.stackable]).[br]
## [b]Примечание[/b]: этот метод может быть вызван только сервером и только как RPC.
@rpc("authority", "reliable", "call_local", 4)
func add_effect(effect_id: String, duration := 1.0, data := [], should_stack := true) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	var effect: Effect = (load(effect_id) as PackedScene).instantiate()
	if not effect.stackable or not should_stack:
		for existing_effect: Effect in _effects.get_children():
			if existing_effect.id == effect_id:
				existing_effect.add_duration(duration)
				effect.free()
				print_verbose("Added duration %f to effect %s on entity %s." % [
					duration,
					effect.name,
					name,
				])
				return
	
	_effects.add_child(effect)
	effect.initialize(self, effect_id, data, false, duration)
	print_verbose("Added effect %s with duration %f to entity %s." % [
		effect.name,
		duration,
		name,
	])


## Добавляет постоянный эффект на сущность. В [param effect_id] должна быть передана одна из
## констант класса [Effect] с UID нужного эффекта.
## В [param data] могут быть переданы данные для эффекта (если требуются).
## [param should_stack] может отключить возможность стакаться эффекту
## (если она уже не была отключена с помощью [member Effect.stackable]).[br]
## [b]Примечание[/b]: этот метод должен вызваться только сервером и только как RPC.
@rpc("authority", "reliable", "call_local", 4)
func add_timeless_effect(effect_id: String, data := [], should_stack := true) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	var effect: Effect = (load(effect_id) as PackedScene).instantiate()
	if not effect.stackable or not should_stack:
		for existing_effect: Effect in _effects.get_children():
			if existing_effect.id == effect_id:
				existing_effect.timeless_counter += 1
				effect.free()
				print_verbose("Increased counter of effect %s on entity %s." % [effect.name, name])
				return
	
	_effects.add_child(effect)
	effect.initialize(self, effect_id, data, true)
	print_verbose("Added timeless effect %s to entity %s." % [effect.name, name])


## Удаляет постоянный эффект с сущности, или уменьшает счётчик на нём. В [param effect_id] должна
## быть передана одна из констант класса [Effect] с UID нужного эффекта.[br]
## [b]Примечание[/b]: этот метод должен вызываться только сервером и только как RPC.
@rpc("authority", "reliable", "call_local", 4)
func remove_timeless_effect(effect_id: String) -> void:
	if is_queued_for_deletion():
		print_verbose("Entity %s is going to be deleted. Effect with ID %s is not removed." % [
			name,
			effect_id,
		])
		return
	
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	var effects: Array[Node] = _effects.get_children()
	effects.reverse()
	for effect: Effect in effects:
		if effect.id == effect_id:
			effect.timeless_counter -= 1
			print_verbose("Removed timeless effect %s on entity %s." % [effect.name, name])
			return

## Очищает все эффекты с сущности, основываясь на [param positive] и [param negative].[br]
## [b]Примечание[/b]: этот метод должен вызываться только сервером и только как RPC.
@rpc("authority", "reliable", "call_local", 4)
func clear_effects(negative := true, positive := false) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	for effect: Effect in _effects.get_children():
		if effect.negative == negative or effect.negative != positive:
			effect.clear()
			print_verbose("Cleared %s effect %s on entity %s." % [
				"negative" if effect.negative else "positive",
				effect.name,
				name,
			])
#endregion


#region Методы здоровья
## Устанавливает здоровье на [param health].[br]
## [b]Примечание[/b]: этот метод должен вызываться только сервером и только как RPC.
@rpc("call_local", "reliable", "authority", 4)
func set_health(health: int) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	if current_health <= 0:
		return
	if health <= 0:
		current_health = 0
		died.emit(id)
		if death_vfx_scene:
			var death_vfx: Node2D = death_vfx_scene.instantiate()
			death_vfx.position = position
			_vfx_parent.add_child(death_vfx)
		print_verbose("Entity %s died." % name)
		if multiplayer.is_server():
			queue_free()
		return
	
	health_changed.emit(current_health, health)
	if health < current_health:
		if hurt_vfx_scene:
			var hurt_vfx: Node2D = hurt_vfx_scene.instantiate()
			hurt_vfx.position = position
			_vfx_parent.add_child(hurt_vfx)
		if _numbers_vfx_scene:
			var numbers_vfx: Node2D = _numbers_vfx_scene.instantiate()
			numbers_vfx.position = position
			(numbers_vfx.get_node(^"Label") as Label).text = str(current_health - health)
			if is_local():
				(numbers_vfx.get_node(^"Label") as Label).add_theme_color_override(
						&"font_color", Color.RED)
			_vfx_parent.add_child(numbers_vfx)
	else: 
		if heal_vfx_scene:
			var heal_vfx: Node2D = heal_vfx_scene.instantiate()
			heal_vfx.position = position
			_vfx_parent.add_child(heal_vfx)
		if _numbers_vfx_scene:
			var numbers_vfx: Node2D = _numbers_vfx_scene.instantiate()
			numbers_vfx.position = position
			(numbers_vfx.get_node(^"Label") as Label).text = str(health - current_health)
			(numbers_vfx.get_node(^"Label") as Label).add_theme_color_override(
					&"font_color", Color.GREEN)
			_vfx_parent.add_child(numbers_vfx)
	
	current_health = health
	if current_health > max_health:
		max_health = current_health
	print_verbose("Entity %s changed health: %d/%d." % [name, current_health, max_health])


## Понижает здоровье на [param amount] с учётом [member defense_multiplier].
## [param by] должен содержать ID сущности, нанёсшей урон.[br]
## [b]Примечание[/b]: этот метод должен вызываться только на сервере.
func damage(amount: int, by: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client.")
		return
	if is_immune() or current_health <= 0 or amount <= 0:
		return
	
	var new_health: int = clampi(current_health - maxi(roundi(amount * defense_multiplier), 1),
			0, max_health)
	if new_health <= 0:
		killed.emit(id, by)
	else:
		damaged.emit(id, by)
	set_health.rpc(new_health)


## Восстанавливает [param amount] здоровья.[br]
## [b]Примечание[/b]: этот метод должен вызываться только на сервере.
func heal(amount: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client.")
		return
	if current_health <= 0 or amount <= 0 or current_health >= max_health:
		return
	
	var new_health: int = clampi(current_health + amount, 0, max_health)
	set_health.rpc(new_health)
#endregion


#region Функции для изменения состояний сущности
## Делает сущность невосприимчивой к любому урону.
func make_immune() -> void:
	_immune_counter += 1


## Убирает невосприимчивость сущности к урону.
func unmake_immune() -> void:
	_immune_counter -= 1


## Возвращает [code]true[/code], если сущность в данный момент имеет иммунитет к урону.
func is_immune() -> bool:
	return _immune_counter > 0


## Забирает у сущности возможность контролировать своё движение.
func make_immobile() -> void:
	_immobile_counter += 1


## Возвращает сущности возможность контролировать своё движение.
func unmake_immobile() -> void:
	_immobile_counter -= 1


## Возвращает [code]true[/code], если сущность в данный момент
## не может контролировать своё движение.
func is_immobile() -> bool:
	return _immobile_counter > 0


## Обезоруживает сущность.
func make_disarmed() -> void:
	_disarmed_counter += 1


## Возвращает сущности вощможность пользоваться оружием.
func unmake_disarmed() -> void:
	_disarmed_counter -= 1


## Возвращает [code]true[/code], если сущность в данный момент обезоружена.
func is_disarmed() -> bool:
	return _disarmed_counter > 0
#endregion


## Возвращает [code]true[/code], если сущность контролируется локальным устройством
## (т.е. не другим клиентом/сервером).
func is_local() -> bool:
	return entity_input.is_multiplayer_authority()
