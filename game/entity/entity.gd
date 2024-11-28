class_name Entity
extends CharacterBody2D


signal health_changed(old_value: int, new_value: int)
signal damaged(who: int, by: int)
signal killed(who: int, by: int)
signal died(who: int)

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

@export var speed := 640.0
@export var max_health: int = 100
@export var magic := 1600.0
@export var hurt_vfx_scene: PackedScene
@export var death_vfx_scene: PackedScene
@export var heal_vfx_scene: PackedScene

var id: int = -1:
	set(value):
		id = value
		$Input.set_multiplayer_authority(value if id > 0 else 1)
var current_health: int = 100
var team: int = 0
var speed_multiplier := 1.0
var damage_multiplier := 1.0
var defense_multiplier := 1.0
var knockback := Vector2.ZERO
var server_position := Vector2.ZERO

var _immune_counter: int = 0
var _immobile_counter: int = 0
var _disarmed_counter: int = 0

@onready var entity_input: EntityInput = $Input
@onready var visual: Node2D = $Visual
@onready var _effects: Node2D = $Effects
@onready var _vfx_parent: Node2D = get_tree().get_first_node_in_group(&"VfxParent")


func _ready() -> void:
	current_health = max_health
	server_position = position


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
		position = position.lerp(
				server_position,
				clampf(position.distance_to(server_position) / magic * delta, 0.0, 1.0)
		)
	
	if not is_zero_approx(self_velocity.x):
		visual.scale.x = -1 if self_velocity.x < 0 else 1


#region Методы эффектов
@rpc("authority", "reliable", "call_local", 3)
func add_effect(effect_id: String, duration := 1.0, data := [], should_stack := true) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	var effect: Effect = (load(effect_id) as PackedScene).instantiate()
	if not effect.stackable or not should_stack:
		for i: Effect in _effects.get_children():
			if i.id == effect_id:
				i.add_duration(duration)
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


@rpc("authority", "reliable", "call_local", 3)
func add_timeless_effect(effect_id: String, data := [], should_stack := true) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	var effect: Effect = (load(effect_id) as PackedScene).instantiate()
	if not effect.stackable or not should_stack:
		for i: Effect in _effects.get_children():
			if i.id == effect_id:
				i.timeless_counter += 1
				effect.free()
				print_verbose("Increased counter of effect %s on entity %s." % [effect.name, name])
				return
	
	_effects.add_child(effect)
	effect.initialize(self, effect_id, data, true)
	print_verbose("Added timeless effect %s to entity %s." % [effect.name, name])


@rpc("authority", "reliable", "call_local", 3)
func remove_timeless_effect(effect_id: String) -> void:
	if is_queued_for_deletion():
		print_verbose("Entity %s is going to be deleted. Effect with ID %s is not removed." % [
			name,
			effect_id,
		])
		return
	
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	var effects: Array[Node] = _effects.get_children()
	effects.reverse()
	for i: Effect in effects:
		if i.id == effect_id:
			i.timeless_counter -= 1
			print_verbose("Removed timeless effect %s on entity %s." % [i.name, name])
			return


@rpc("authority", "reliable", "call_local", 3)
func clear_effects(negative := true, positive := false) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	for i: Effect in _effects.get_children():
		if i.negative == negative or i.negative != positive:
			i.clear()
			print_verbose("Cleared %s effect %s on entity %s." % [
				"negative" if i.negative else "positive",
				i.name,
				name,
			])
#endregion


#region Методы здоровья
@rpc("call_local", "reliable", "authority", 1)
func set_health(health: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
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
	else: 
		if heal_vfx_scene:
			var heal_vfx: Node2D = heal_vfx_scene.instantiate()
			heal_vfx.position = position
			_vfx_parent.add_child(heal_vfx)
	current_health = health
	if current_health > max_health:
		max_health = current_health
	print_verbose("Entity %s changed health: %d/%d." % [name, current_health, max_health])


func damage(amount: int, by: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	if is_immune() or current_health <= 0 or amount <= 0:
		return
	
	var new_health: int = clampi(
			current_health - maxi(roundi(amount * defense_multiplier), 1), 0, max_health
	)
	if new_health <= 0:
		killed.emit(id, by)
	else:
		damaged.emit(id, by)
	set_health.rpc(new_health)


func heal(amount: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	if current_health <= 0 or amount <= 0 or current_health >= max_health:
		return
	
	var new_health: int = clampi(current_health + amount, 0, max_health)
	set_health.rpc(new_health)
#endregion


#region Функции для изменения состояний сущности
func make_immune() -> void:
	_immune_counter += 1


func unmake_immune() -> void:
	_immune_counter -= 1


func is_immune() -> bool:
	return _immune_counter > 0


func make_immobile() -> void:
	_immobile_counter += 1


func unmake_immobile() -> void:
	_immobile_counter -= 1


func is_immobile() -> bool:
	return _immobile_counter > 0


func make_disarmed() -> void:
	_disarmed_counter += 1


func unmake_disarmed() -> void:
	_disarmed_counter -= 1


func is_disarmed() -> bool:
	return _disarmed_counter > 0
#endregion


func is_local() -> bool:
	return entity_input.is_multiplayer_authority()
