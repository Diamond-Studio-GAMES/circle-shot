class_name Player
extends CharacterBody2D


signal health_changed(old_value: int, new_value: int)
signal killed(who: int, by: int)
signal died(who: int)
signal weapon_changed(type: Weapon.Type)
signal ammo_text_updated(text: String)
@export var SPEED := 640.0
# ВизЭффекты
@export var hurt_vfx: PackedScene
@export var death_vfx: PackedScene
@export var heal_vfx: PackedScene
# Синхронизируются при спавне
var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)
var team := 0
var player_name := "Колобок"
var weapons_data: Array
# Переменные состояния
var can_control := true
var can_use_weapon := true
var current_health := 100
var max_health := 100
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var server_position := Vector2.ZERO
var _going_to_die := false
var _current_weapon: Weapon
var _current_weapon_type: Weapon.Type
@onready var remote_transform: RemoteTransform2D = $RemoteTransform
@onready var input: PlayerInput = $PlayerInput
@onready var _visual: Node2D = $Visual
@onready var _blood: GPUParticles2D = $Visual/Blood
@onready var _weapon_timer: Timer = $WeaponTimer
@onready var _weapons: Node2D = $Visual/Weapons
@onready var _effects: Node2D = $Effects
@onready var _vfx_parent: Node2D = get_tree().get_first_node_in_group("VFXParent")


func _ready() -> void:
	($Name/Label as Label).text = player_name
	($Name/Label as Label).self_modulate = Game.TEAM_COLORS[team]
	if player == multiplayer.get_unique_id():
		(get_tree().current_scene as Shooter).game.set_local_player(self)
		($ControlIndicator as Node2D).show()
		($ControlIndicator as Node2D).self_modulate = Game.TEAM_COLORS[team]
	
	var light_weapon_scene: PackedScene = load(Global.items_db.weapons_light[weapons_data[0]].weapon_path)
	var light_weapon: Weapon = light_weapon_scene.instantiate()
	light_weapon.player = self
	_weapons.add_child(light_weapon)
	light_weapon.hide()
	light_weapon.process_mode = PROCESS_MODE_DISABLED
	var heavy_weapon_scene: PackedScene = load(Global.items_db.weapons_heavy[weapons_data[1]].weapon_path)
	var heavy_weapon: Weapon = heavy_weapon_scene.instantiate()
	heavy_weapon.player = self
	_weapons.add_child(heavy_weapon)
	heavy_weapon.hide()
	heavy_weapon.process_mode = PROCESS_MODE_DISABLED
	var support_weapon_scene: PackedScene = load(Global.items_db.weapons_support[weapons_data[2]].weapon_path)
	var support_weapon: Weapon = support_weapon_scene.instantiate()
	support_weapon.player = self
	_weapons.add_child(support_weapon)
	support_weapon.hide()
	support_weapon.process_mode = PROCESS_MODE_DISABLED
	var melee_weapon_scene: PackedScene = load(Global.items_db.weapons_melee[weapons_data[3]].weapon_path)
	var melee_weapon: Weapon = melee_weapon_scene.instantiate()
	melee_weapon.player = self
	_weapons.add_child(melee_weapon)
	melee_weapon.hide()
	melee_weapon.process_mode = PROCESS_MODE_DISABLED
	
	_current_weapon = light_weapon
	_current_weapon_type = Weapon.Type.LIGHT
	_current_weapon.make_current()
	weapon_changed.emit(Weapon.Type.LIGHT)
	ammo_text_updated.emit(_current_weapon.get_ammo_text())


func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer:
		if multiplayer.is_server():
			velocity = input.direction.normalized() * SPEED * speed_multiplier * int(can_control)
			move_and_slide()
			server_position = position
		else:
			position = position.move_toward(server_position, SPEED * speed_multiplier * delta)
	
	if velocity.x != 0.0:
		_visual.scale.x = -1 if velocity.x < 0 else 1
	if can_control:
		_visual.scale.x = -1 if input.aiming_direction.x < 0 else 1


@rpc("call_local", "reliable", "authority", 1)
func set_health(health: int) -> void:
	if _going_to_die:
		return
	if health == current_health:
		return
	if health <= 0:
		current_health = 0
		died.emit(player)
		if multiplayer.is_server():
			queue_free()
		_going_to_die = true
		var death_vfx_node: Node2D = death_vfx.instantiate()
		death_vfx_node.position = position
		_vfx_parent.add_child(death_vfx_node)
		return
	health_changed.emit(current_health, health)
	if health < current_health:
		var hurt_vfx_node: Node2D = hurt_vfx.instantiate()
		hurt_vfx_node.position = position
		_vfx_parent.add_child(hurt_vfx_node)
	else: 
		var heal_vfx_node: Node2D = heal_vfx.instantiate()
		heal_vfx_node.position = position
		_vfx_parent.add_child(heal_vfx_node)
	current_health = health
	if current_health < max_health * 0.33:
		_blood.emitting = true
	else:
		_blood.emitting = false
	if current_health > max_health:
		max_health = current_health


func damage(amount: int, by: int) -> void:
	if not multiplayer.is_server():
		return
	if current_health <= 0:
		return
	var new_health := clampi(current_health - amount, 0, max_health)
	if new_health <= 0:
		killed.emit(player, by)
	set_health.rpc(new_health)


func heal(amount: int) -> void:
	if not multiplayer.is_server():
		return
	var new_health := clampi(current_health + amount, 0, max_health)
	set_health.rpc(new_health)


func request_change_weapon(to: Weapon.Type) -> void:
	if to == _current_weapon_type:
		return
	if not multiplayer.is_server():
		_change_weapon_requested.rpc_id(1, to)
	else:
		if not (can_use_weapon and can_control):
			return
		change_weapon.rpc(to)


@rpc("call_local", "reliable", "authority", 2)
func change_weapon(to: Weapon.Type) -> void:
	_current_weapon.unmake_current()
	_current_weapon = _weapons.get_child(to)
	_current_weapon.make_current()
	_current_weapon_type = to
	weapon_changed.emit(to)
	ammo_text_updated.emit(_current_weapon.get_ammo_text())


func lock_weapon_use(time: float) -> void:
	can_use_weapon = false
	_weapon_timer.start(time + _weapon_timer.time_left)


@rpc("authority", "reliable", "call_local", 3)
func add_effect(effect_path: String, duration: float = 1.0, data := [], should_stack := true) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var effect_node: Effect = (load(effect_path) as PackedScene).instantiate()
	if not effect_node.can_stack or not should_stack:
		var path_to_exist_effect := NodePath(effect_node.name)
		if _effects.has_node(path_to_exist_effect):
			(_effects.get_node(path_to_exist_effect) as Effect).duration += duration
			effect_node.free()
			return
	effect_node.player = self
	effect_node.duration = duration
	effect_node.data = data
	_effects.add_child(effect_node)


@rpc("any_peer", "reliable", "call_remote", 2)
func _change_weapon_requested(to: Weapon.Type) -> void:
	if not multiplayer.is_server():
		return
	if to == _current_weapon_type:
		return
	if not (can_use_weapon and can_control):
		return
	if player != multiplayer.get_remote_sender_id():
		return
	change_weapon.rpc(to)


func _on_weapon_timer_timeout() -> void:
	can_use_weapon = true
