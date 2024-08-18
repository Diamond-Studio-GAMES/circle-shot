class_name Player
extends Entity


signal weapon_changed(type: Weapon.Type)
signal ammo_text_updated(text: String)
# Синхронизируются при спавне
var player_name := "Колобок"
var equip_data: Array[int]
var _current_weapon: Weapon
var _current_weapon_type: Weapon.Type
@onready var player_input: PlayerInput = $Input
@onready var _blood: GPUParticles2D = $Visual/Blood
@onready var _weapons: Node2D = $Visual/Weapons


func _ready() -> void:
	super()
	
	($Name/Label as Label).text = player_name
	($Name/Label as Label).self_modulate = TEAM_COLORS[team]
	if id == multiplayer.get_unique_id():
		(get_tree().get_first_node_in_group(&"Event") as Event).set_local_player(self)
		($ControlIndicator as Node2D).show()
		($ControlIndicator as Node2D).self_modulate = TEAM_COLORS[team]
	
	set_skin(equip_data[0])
	
	#var light_weapon_scene: PackedScene = load(Globals.items_db.weapons_light[weapons_data[0]].weapon_path)
	#var light_weapon: Weapon = light_weapon_scene.instantiate()
	#light_weapon.player = self
	#_weapons.add_child(light_weapon)
	#light_weapon.hide()
	#light_weapon.process_mode = PROCESS_MODE_DISABLED
	#var heavy_weapon_scene: PackedScene = load(Globals.items_db.weapons_heavy[weapons_data[1]].weapon_path)
	#var heavy_weapon: Weapon = heavy_weapon_scene.instantiate()
	#heavy_weapon.player = self
	#_weapons.add_child(heavy_weapon)
	#heavy_weapon.hide()
	#heavy_weapon.process_mode = PROCESS_MODE_DISABLED
	#var support_weapon_scene: PackedScene = load(Globals.items_db.weapons_support[weapons_data[2]].weapon_path)
	#var support_weapon: Weapon = support_weapon_scene.instantiate()
	#support_weapon.player = self
	#_weapons.add_child(support_weapon)
	#support_weapon.hide()
	#support_weapon.process_mode = PROCESS_MODE_DISABLED
	#var melee_weapon_scene: PackedScene = load(Globals.items_db.weapons_melee[weapons_data[3]].weapon_path)
	#var melee_weapon: Weapon = melee_weapon_scene.instantiate()
	#melee_weapon.player = self
	#_weapons.add_child(melee_weapon)
	#melee_weapon.hide()
	#melee_weapon.process_mode = PROCESS_MODE_DISABLED
	#
	#_current_weapon = light_weapon
	#_current_weapon_type = Weapon.Type.LIGHT
	#_current_weapon.make_current()
	#weapon_changed.emit(Weapon.Type.LIGHT)
	#ammo_text_updated.emit(_current_weapon.get_ammo_text())


func _physics_process(delta: float) -> void:
	super(delta)
	if player_input.aiming:
		_visual.scale.x = -1 if player_input.aim_direction.x < 0 else 1


@rpc("call_local", "reliable", "authority", 2)
func change_weapon(to: Weapon.Type) -> void:
	_current_weapon.unmake_current()
	_current_weapon = _weapons.get_child(to)
	_current_weapon.make_current()
	_current_weapon_type = to
	weapon_changed.emit(to)
	ammo_text_updated.emit(_current_weapon.get_ammo_text())


func request_change_weapon(to: Weapon.Type) -> void:
	if to == _current_weapon_type:
		return
	if not multiplayer.is_server():
		_change_weapon_requested.rpc_id(1, to)
	else:
		if is_disarmed():
			return
		change_weapon.rpc(to)


func set_skin(skin_id: int) -> void:
	for i: Node in $Visual/Skin.get_children():
		i.queue_free()
	
	var skin_scene: PackedScene = load(Globals.items_db.skins[skin_id].scene_path)
	var skin: PlayerSkin = skin_scene.instantiate()
	skin.player = self
	$Visual/Skin.add_child(skin)


@rpc("any_peer", "reliable", "call_remote", 2)
func _change_weapon_requested(to: Weapon.Type) -> void:
	if not multiplayer.is_server():
		return
	if to == _current_weapon_type:
		return
	if is_disarmed():
		return
	if id != multiplayer.get_remote_sender_id():
		return
	change_weapon.rpc(to)


func _on_health_changed(_old_value: int, _new_value: int) -> void:
	if current_health < max_health / 3.0:
		_blood.emitting = true
	else:
		_blood.emitting = false
