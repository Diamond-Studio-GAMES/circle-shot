class_name Entity
extends CharacterBody2D


signal health_changed(old_value: int, new_value: int)
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
		$Input.set_multiplayer_authority(value)
var current_health: int = 100
var team: int = 0
var speed_multiplier := 1.0
var damage_multiplier := 1.0
var defense_multiplier := 1.0
var immune_counter: int = 0
var immobile_counter: int = 0
var disarmed_counter: int = 0
var knockback := Vector2.ZERO
var server_position := Vector2.ZERO
@onready var entity_input: EntityInput = $Input
@onready var _effects: Node2D = $Effects
@onready var _visual: Node2D = $Visual
@onready var _vfx_parent: Node2D = get_tree().get_first_node_in_group("VFXParent")


func _ready() -> void:
	current_health = max_health
	server_position = position


func _physics_process(delta: float) -> void:
	velocity = knockback
	if not is_immobile():
		if entity_input.direction.length_squared() < 1.0:
			velocity += entity_input.direction * speed * speed_multiplier
		else:
			velocity += entity_input.direction.normalized() * speed * speed_multiplier
	move_and_slide()
	if multiplayer.is_server():
		server_position = position
	else:
		position = position.lerp(
				server_position,
				clampf(position.distance_to(server_position) / magic * delta, 0.0, 1.0)
		)
	
	if not is_zero_approx(velocity.x):
		_visual.scale.x = -1 if velocity.x < 0 else 1


@rpc("call_local", "reliable", "authority", 1)
func set_health(health: int) -> void:
	if current_health <= 0:
		return
	if health == current_health:
		return
	if health <= 0:
		current_health = 0
		died.emit(id)
		if multiplayer.is_server():
			queue_free()
		if death_vfx_scene:
			var death_vfx: Node2D = death_vfx_scene.instantiate()
			death_vfx.position = position
			_vfx_parent.add_child(death_vfx)
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


func damage(amount: int, by: int) -> void:
	if not multiplayer.is_server():
		return
	if current_health <= 0:
		return
	var new_health := clampi(current_health - amount, 0, max_health)
	if new_health <= 0:
		killed.emit(id, by)
	set_health.rpc(new_health)


func heal(amount: int) -> void:
	if not multiplayer.is_server():
		return
	var new_health := clampi(current_health + amount, 0, max_health)
	set_health.rpc(new_health)


@rpc("authority", "reliable", "call_local", 3)
func add_effect(effect_path: String, duration := 1.0, data := [], should_stack := true) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var effect: Effect = (load(effect_path) as PackedScene).instantiate()
	if not effect.can_stack or not should_stack:
		var path_to_exist_effect := NodePath(effect.name)
		if _effects.has_node(path_to_exist_effect):
			(_effects.get_node(path_to_exist_effect) as Effect).duration += duration
			effect.free()
			return
	effect.entity = self
	effect.duration = duration
	effect.data = data
	_effects.add_child(effect)


#region Функции для изменения состояний сущности
func make_immune() -> void:
	immune_counter += 1


func unmake_immune() -> void:
	immune_counter -= 1


func is_immune() -> bool:
	return immune_counter > 0


func make_immobile() -> void:
	immobile_counter += 1


func unmake_immobile() -> void:
	immobile_counter -= 1


func is_immobile() -> bool:
	return immobile_counter > 0


func make_disarmed() -> void:
	disarmed_counter += 1


func unmake_disarmed() -> void:
	disarmed_counter -= 1


func is_disarmed() -> bool:
	return disarmed_counter > 0
#endregion
