class_name Player
extends Entity


signal weapon_changed(type: Weapon.Type)
signal weapon_equipped(type: Weapon.Type, data: WeaponData)
signal ammo_text_updated(text: String)
signal skill_equipped(data: SkillData)

var player_name := "Колобок"
var equip_data: Array[int]
var skill_vars: Array[int]
var skin: PlayerSkin
var current_weapon: Weapon
var current_weapon_type := Weapon.Type.LIGHT
var skill: Skill

@onready var player_input: PlayerInput = $Input
@onready var blood: CPUParticles2D = $Visual/Blood
@onready var _weapons: Node2D = $Visual/Weapons
@onready var _event: Event = get_tree().get_first_node_in_group(&"Event")


func _ready() -> void:
	super()
	
	($Name/Label as Label).text = player_name
	($Name/Label as Label).self_modulate = TEAM_COLORS[team]
	if is_local():
		_event.set_local_player(self)
		_event.set_local_team(team)
		($ControlIndicator as Node2D).show()
		($ControlIndicator as Node2D).self_modulate = TEAM_COLORS[team]
		($AudioListener2D as AudioListener2D).make_current()
	
	
	set_skin(Globals.items_db.skins[equip_data[0]])
	
	set_weapon(
			Weapon.Type.LIGHT,
			Globals.items_db.weapons_light[equip_data[1]] if equip_data[1] >= 0 else null
	)
	set_weapon(
			Weapon.Type.HEAVY,
			Globals.items_db.weapons_heavy[equip_data[2]] if equip_data[2] >= 0 else null
	)
	set_weapon(
			Weapon.Type.SUPPORT,
			Globals.items_db.weapons_support[equip_data[3]] if equip_data[3] >= 0 else null
	)
	set_weapon(
			Weapon.Type.MELEE,
			Globals.items_db.weapons_melee[equip_data[4]] if equip_data[4] >= 0 else null
	)
	
	set_skill(Globals.items_db.skills[equip_data[5]] if equip_data[5] >= 0 else null)
	
	($Minimap/MinimapMarker/Visual as Node2D).self_modulate = TEAM_COLORS[team]
	await get_tree().process_frame
	_update_minimap_marker()
	_event.local_team_set.connect(_update_minimap_marker)


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
	_request_change_weapon.rpc_id(1, to)


func try_reload_weapon() -> void:
	_request_reload.rpc_id(1)


func try_use_additional_button_weapon() -> void:
	_request_additional_button.rpc_id(1)


func try_use_skill() -> void:
	_request_use_skill.rpc_id(1)


func set_skin(data: SkinData) -> void:
	for i: Node in $Visual/Skin.get_children():
		i.queue_free()
	
	var skin_scene: PackedScene = load(data.scene_path)
	skin = skin_scene.instantiate()
	skin.data = data
	skin.player = self
	$Visual/Skin.add_child(skin)
	equip_data[0] = data.idx_in_db
	print_verbose("Skin %s with ID %d on player %s set." % [data.id, equip_data[0], name])


func set_weapon(type: Weapon.Type, data: WeaponData) -> void:
	var old_weapon: Node = _weapons.get_child(type)
	if old_weapon == current_weapon:
		(old_weapon as Weapon).unmake_current()
	# чтобы не мешало при возни с индексами и move_child
	_weapons.remove_child(old_weapon)
	old_weapon.queue_free()
	
	if not data:
		var placeholder := Node.new()
		placeholder.name = "NoWeapon%d" % type
		_weapons.add_child(placeholder)
		_weapons.move_child(placeholder, type)
		equip_data[1 + type] = -2 # TODO: задокументить
		weapon_equipped.emit(type, null)
		print_verbose("Removed weapon with type %d on player %s." % [type, name])
		
		if current_weapon_type == type:
			_set_current_weapon(type)
		return
	
	var weapon_path: String = data.scene_path
	var weapon_scene: PackedScene = load(weapon_path)
	var weapon: Weapon = weapon_scene.instantiate()
	_weapons.add_child(weapon)
	_weapons.move_child(weapon, type)
	weapon.initialize(self, data)
	equip_data[1 + type] = data.idx_in_db
	
	weapon_equipped.emit(type, data)
	print_verbose("Set weapon %s with ID %d with type %d on player %s." % [
		data.id,
		data.idx_in_db,
		type,
		name,
	])
	
	if current_weapon_type == type or not current_weapon:
		_set_current_weapon(type)


func set_skill(data: SkillData, reset_skill_vars := false) -> void:
	if reset_skill_vars:
		skill_vars.clear()
	
	if is_instance_valid(skill):
		remove_child(skill)
		skill.queue_free()
	
	if not data:
		skill = null
		skill_equipped.emit(data)
		print_verbose("Removed skill on player %s." % name)
		return
	
	var skill_scene: PackedScene = load(data.scene_path)
	skill = skill_scene.instantiate()
	add_child(skill)
	skill.initialize(self, data)
	equip_data[5] = data.idx_in_db
	skill_equipped.emit(data)
	print_verbose("Set skill %s with ID %d on player %s." % [data.id, equip_data[5], name])


@rpc("any_peer", "reliable", "call_local", 2)
func _request_change_weapon(to: Weapon.Type) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, id
		])
		return
	if to == current_weapon_type or is_disarmed():
		return
	
	change_weapon.rpc(to)


@rpc("any_peer", "reliable", "call_local", 2)
func _request_reload() -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, id
		])
		return
	if is_disarmed() or not is_instance_valid(current_weapon) or not current_weapon.can_reload():
		return
	
	reload_weapon.rpc()


@rpc("any_peer", "reliable", "call_local", 2)
func _request_additional_button() -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, id
		])
		return
	if is_disarmed() or not is_instance_valid(current_weapon) \
			or not current_weapon.has_additional_button():
		return
	
	additional_button_weapon.rpc()


@rpc("any_peer", "reliable", "call_local", 2)
func _request_use_skill() -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, id
		])
		return
	
	if is_disarmed() or not is_instance_valid(skill) or not skill.can_use():
		return
	
	use_skill.rpc()


func _set_current_weapon(to: Weapon.Type) -> void:
	current_weapon = _weapons.get_child(to) as Weapon
	if current_weapon:
		current_weapon.make_current()
	ammo_text_updated.emit(current_weapon.get_ammo_text() if current_weapon else "Нет оружия")
	current_weapon_type = to
	weapon_changed.emit(to)
	print_verbose("Player %s changed current weapon to type %d." % [name, to])


func _update_minimap_marker() -> void:
	if team == _event.local_team:
		($Minimap/MinimapMarker/Visual as Node2D).show()
		($Minimap/MinimapNotifier as Node2D).hide()
	else:
		($Minimap/MinimapMarker/Visual as Node2D).visible = \
				($Minimap/MinimapNotifier as VisibleOnScreenNotifier2D).is_on_screen()


func _on_health_changed(_old_value: int, new_value: int) -> void:
	blood.emitting = new_value < max_health / 3.0
