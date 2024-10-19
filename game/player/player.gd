class_name Player
extends Entity


signal weapon_changed(type: Weapon.Type)
signal weapon_equipped(type: Weapon.Type, id: int)
signal ammo_text_updated(text: String)
signal skill_equipped(id: int)

var player_name := "Колобок"
var equip_data: Array[int]
var skill_vars: Array[int]
var current_weapon: Weapon
var current_weapon_type := Weapon.Type.LIGHT
var skill: Skill

@onready var player_input: PlayerInput = $Input
@onready var _blood: CPUParticles2D = $Visual/Blood
@onready var _weapons: Node2D = $Visual/Weapons


func _ready() -> void:
	super()
	
	($Name/Label as Label).text = player_name
	($Name/Label as Label).self_modulate = TEAM_COLORS[team]
	if is_local():
		(get_tree().get_first_node_in_group(&"Event") as Event).set_local_player(self)
		($ControlIndicator as Node2D).show()
		($ControlIndicator as Node2D).self_modulate = TEAM_COLORS[team]
		($AudioListener2D as AudioListener2D).make_current()
	
	set_skin(equip_data[0])
	
	set_weapon(Weapon.Type.LIGHT, equip_data[1])
	set_weapon(Weapon.Type.HEAVY, equip_data[2])
	set_weapon(Weapon.Type.SUPPORT, equip_data[3])
	set_weapon(Weapon.Type.MELEE, equip_data[4])
	
	set_skill(equip_data[5])
	
	($Minimap/MinimapMarker/Visual as Node2D).self_modulate = TEAM_COLORS[team]
	await get_tree().process_frame
	if team == (get_tree().get_first_node_in_group(&"Event") as Event).local_team:
		($Minimap/MinimapMarker/Visual as Node2D).show()
		($Minimap/MinimapNotifier as Node2D).hide()
	else:
		($Minimap/MinimapMarker/Visual as Node2D).visible = \
				($Minimap/MinimapNotifier as VisibleOnScreenNotifier2D).is_on_screen()


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_disarmed():
		visual.scale.x = -1 if player_input.aim_direction.x < 0 else 1


@rpc("call_local", "reliable", "authority", 2)
func change_weapon(to: Weapon.Type) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	if is_instance_valid(current_weapon):
		current_weapon.unmake_current()
	
	_set_current_weapon(to)


@rpc("call_local", "reliable", "authority", 2)
func reload_weapon() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	current_weapon.reload()


@rpc("call_local", "reliable", "authority", 2)
func additional_button_weapon() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	current_weapon.additional_button()


@rpc("call_local", "reliable", "authority", 2)
func add_ammo_to_weapon(type: Weapon.Type, percent: float) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	var target_weapon: Weapon = _weapons.get_child(type)
	target_weapon.ammo_in_stock = mini(
			target_weapon.ammo_in_stock + ceili(target_weapon.ammo_total * percent),
			target_weapon.ammo_total - target_weapon.ammo_per_load,
	)
	ammo_text_updated.emit(current_weapon.get_ammo_text())


@rpc("call_local", "reliable", "authority", 2)
func use_skill() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	skill.use()


func try_change_weapon(to: Weapon.Type) -> void:
	if to == current_weapon_type:
		return
	if not multiplayer.is_server():
		_request_change_weapon.rpc_id(1, to)
	else:
		_request_change_weapon(to)


func try_reload_weapon() -> void:
	if not multiplayer.is_server():
		_request_reload.rpc_id(1)
	else:
		_request_reload()


func try_use_additional_button_weapon() -> void:
	if not multiplayer.is_server():
		_request_additional_button.rpc_id(1)
	else:
		_request_additional_button()


func try_use_skill() -> void:
	if not multiplayer.is_server():
		_request_use_skill.rpc_id(1)
	else:
		_request_use_skill()


func set_skin(skin_id: int) -> void:
	for i: Node in $Visual/Skin.get_children():
		i.queue_free()
	
	var skin_scene: PackedScene = load(Globals.items_db.skins[skin_id].scene_path)
	var skin: PlayerSkin = skin_scene.instantiate()
	skin.player = self
	$Visual/Skin.add_child(skin)
	equip_data[0] = skin_id
	print_verbose("Skin on player %d set: %d." % [id, skin_id])


func set_weapon(type: Weapon.Type, weapon_id: int) -> void:
	var old_weapon: Node = _weapons.get_child(type)
	if old_weapon == current_weapon:
		(old_weapon as Weapon).unmake_current()
	# чтобы не мешало при возни с индексами и move_child
	_weapons.remove_child(old_weapon)
	old_weapon.queue_free()
	
	if weapon_id < 0:
		var placeholder := Node.new()
		placeholder.name = "NoWeapon%d" % type
		_weapons.add_child(placeholder)
		_weapons.move_child(placeholder, type)
		equip_data[1 + type] = -1
		weapon_equipped.emit(type, weapon_id)
		print_verbose("Removed weapon with type %d on player %d." % [type, id])
		
		if current_weapon_type == type:
			for i: int in range(1, 5):
				if equip_data[i] >= 0:
					_set_current_weapon(i - 1)
					break
			current_weapon = null
		return
	
	var weapon_path: String
	match type:
		Weapon.Type.LIGHT:
			weapon_path = Globals.items_db.weapons_light[weapon_id].scene_path
		Weapon.Type.HEAVY:
			weapon_path = Globals.items_db.weapons_heavy[weapon_id].scene_path
		Weapon.Type.SUPPORT:
			weapon_path = Globals.items_db.weapons_support[weapon_id].scene_path
		Weapon.Type.MELEE:
			weapon_path = Globals.items_db.weapons_melee[weapon_id].scene_path
	var weapon_scene: PackedScene = load(weapon_path)
	var weapon: Weapon = weapon_scene.instantiate()
	_weapons.add_child(weapon)
	_weapons.move_child(weapon, type)
	weapon.initialize(self)
	equip_data[1 + type] = weapon_id
	weapon_equipped.emit(type, weapon_id)
	print_verbose("Set weapon with ID %d with type %d on player %d" % [weapon_id, type, id])
	
	if current_weapon_type == type:
		_set_current_weapon(type)


func set_skill(skill_id: int, reset_skill_vars := false) -> void:
	if reset_skill_vars:
		skill_vars.clear()
	
	if is_instance_valid(skill):
		remove_child(skill)
		skill.queue_free()
	
	if skill_id < 0:
		skill = null
		skill_equipped.emit(skill_id)
		print_verbose("Removed skill on player %d." % id)
		return
	
	var skill_scene: PackedScene = load(Globals.items_db.skills[skill_id].scene_path)
	var skilln: Skill = skill_scene.instantiate()
	add_child(skilln)
	skilln.initialize(self)
	skill = skilln
	equip_data[5] = skill_id
	skill_equipped.emit(skill_id)
	print_verbose("Set skill with ID %d on player %d" % [skill_id, id])


@rpc("any_peer", "reliable", "call_remote", 2)
func _request_change_weapon(to: Weapon.Type) -> void:
	if not multiplayer.is_server():
		push_error("This method must be called only on server!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, id
		])
		return
	
	if to == current_weapon_type:
		return
	if is_disarmed():
		return
	if equip_data[to + 1] < 0:
		return
	
	change_weapon.rpc(to)


@rpc("any_peer", "reliable", "call_remote", 2)
func _request_reload() -> void:
	if not multiplayer.is_server():
		push_error("This method must be called only on server!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, id
		])
		return
	
	if is_disarmed():
		return
	if not is_instance_valid(current_weapon):
		return
	if not current_weapon.can_reload():
		return
	
	reload_weapon.rpc()


@rpc("any_peer", "reliable", "call_remote", 2)
func _request_additional_button() -> void:
	if not multiplayer.is_server():
		push_error("This method must be called only on server!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, id
		])
		return
	
	if is_disarmed():
		return
	if not is_instance_valid(current_weapon):
		return
	if not current_weapon.has_additional_button():
		return
	
	additional_button_weapon.rpc()


@rpc("any_peer", "reliable", "call_remote", 2)
func _request_use_skill() -> void:
	if not multiplayer.is_server():
		push_error("This method must be called only on server!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, id
		])
		return
	
	if is_disarmed():
		return
	if not is_instance_valid(skill):
		return
	if not skill.can_use():
		return
	
	use_skill.rpc()


func _set_current_weapon(to: Weapon.Type) -> void:
	current_weapon = _weapons.get_child(to)
	current_weapon.make_current()
	current_weapon_type = to
	weapon_changed.emit(to)
	ammo_text_updated.emit(current_weapon.get_ammo_text())
	print_verbose("Player %d changed current weapon to type %d." % [id, to])


func _on_health_changed(_old_value: int, new_value: int) -> void:
	if new_value < max_health / 3.0:
		_blood.emitting = true
	else:
		_blood.emitting = false
