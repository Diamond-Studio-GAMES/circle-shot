extends Control


const MIN_AIM_DIRECTION_LENGTH := 0.1

var aim_deadzone := 60.0
var aim_max_at_distance := 260.0
var sneak_multiplier := 0.5

var _player: Player

var _touch := true
var _moving_left := false
var _moving_right := false
var _moving_up := false
var _moving_down := false
var _aim_zone: float

@onready var _health_bar: TextureProgressBar = $Controller/HealthBar
@onready var _health_text: Label = $Controller/HealthBar/Label
@onready var _blood_vignette: TextureRect = $Controller/BloodVignette
@onready var _tint_anim: AnimationPlayer = $PlayerTint/AnimationPlayer

@onready var _current_weapon_icon: TextureRect = $Controller/CurrentWeapon/Icon
@onready var _light_weapon_icon: TextureRect = $Controller/WeaponSelection/LightWeapon/Icon
@onready var _heavy_weapon_icon: TextureRect = $Controller/WeaponSelection/HeavyWeapon/Icon
@onready var _support_weapon_icon: TextureRect = $Controller/WeaponSelection/SupportWeapon/Icon
@onready var _melee_weapon_icon: TextureRect = $Controller/WeaponSelection/MeleeWeapon/Icon
@onready var _ammo_text: Label = $Controller/CurrentWeapon/Label

@onready var _move_joystick: VirtualJoystick = $Controller/TouchControls/MoveVirtualJoystick
@onready var _aim_joystick: VirtualJoystick = $Controller/TouchControls/AimVirtualJoystick
@onready var _shoot_area: TouchScreenButton = $Controller/TouchControls/ShootArea

@onready var _center: Control = $Center


func _ready() -> void:
	if not OS.has_feature("mobile"):
		($Controller/TouchControls as Control).hide()
		_touch = false
		_aim_zone = aim_max_at_distance - aim_deadzone


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	
	if _touch:
		_player.entity_input.direction = _move_joystick.output
		if not _aim_joystick.output.is_zero_approx():
			var aim: Vector2 = _aim_joystick.output
			_player.player_input.aim_direction = aim.normalized() * MIN_AIM_DIRECTION_LENGTH + \
					aim * (1.0 - MIN_AIM_DIRECTION_LENGTH)
			_player.player_input.showing_aim = true
			_player.player_input.turn_with_aim = true
		else:
			_player.player_input.showing_aim = false
			_player.player_input.turn_with_aim = false
		_player.player_input.shooting = _shoot_area.is_pressed()
	else:
		_player.entity_input.direction = (
			Vector2.LEFT * int(_moving_left) + Vector2.RIGHT * int(_moving_right)
			+ Vector2.UP * int(_moving_up) + Vector2.DOWN * int(_moving_down)
		).normalized()
		if Input.is_action_pressed(&"sneak"):
			_player.entity_input.direction *= sneak_multiplier
		
		var mouse_pos: Vector2 = _center.get_local_mouse_position()
		var mouse_distance: float = mouse_pos.length()
		if mouse_distance > aim_deadzone:
			_player.player_input.aim_direction = mouse_pos.normalized() * ((
					clampf(mouse_distance, aim_deadzone, aim_max_at_distance) - aim_deadzone
			) / _aim_zone * (1.0 - MIN_AIM_DIRECTION_LENGTH) + MIN_AIM_DIRECTION_LENGTH)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_player):
		return
	
	if not _touch:
		if event.is_action(&"shoot"):
			_player.player_input.shooting = event.is_pressed()
		if event.is_action(&"show_aim"):
			_player.player_input.showing_aim = event.is_pressed()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _touch:
		if event.is_action(&"move_left"):
			_moving_left = event.is_pressed()
		if event.is_action(&"move_right"):
			_moving_right = event.is_pressed()
		if event.is_action(&"move_up"):
			_moving_up = event.is_pressed()
		if event.is_action(&"move_down"):
			_moving_down = event.is_pressed()
		
		if event.is_action_pressed(&"show_weapons"):
			if ($Controller/WeaponSelection as Control).visible:
				_close_weapon_selection()
			else:
				open_weapon_selection()
		elif event.is_action_pressed(&"weapon_light"):
			select_weapon(Weapon.Type.LIGHT)
		elif event.is_action_pressed(&"weapon_heavy"):
			select_weapon(Weapon.Type.HEAVY)
		elif event.is_action_pressed(&"weapon_support"):
			select_weapon(Weapon.Type.SUPPORT)
		elif event.is_action_pressed(&"weapon_melee"):
			select_weapon(Weapon.Type.MELEE)
		elif event.is_action_pressed(&"reload"):
			reload()
		elif event.is_action_pressed(&"additional_button"):
			additional_button()


func select_weapon(type: Weapon.Type) -> void:
	_close_weapon_selection()
	if is_instance_valid(_player):
		_player.try_change_weapon(type)


func reload() -> void:
	if is_instance_valid(_player):
		_player.try_reload_weapon()


func additional_button() -> void:
	if is_instance_valid(_player):
		_player.try_use_additional_button_weapon()


func open_weapon_selection() -> void:
	($Controller/WeaponSelection as Control).show()
	($Controller/CurrentWeapon as Control).hide()


func _close_weapon_selection() -> void:
	($Controller/WeaponSelection as Control).hide()
	($Controller/CurrentWeapon as Control).show()


func _on_local_player_created(player: Player) -> void:	
	_on_player_health_changed(player.max_health, player.max_health)
	_tint_anim.play(&"RESET")
	($Controller as Control).show()
	
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	
	player.ammo_text_updated.connect(_on_ammo_text_updated)
	player.weapon_changed.connect(_on_weapon_changed)
	player.weapon_equipped.connect(_on_weapon_equipped)
	player.player_input.turn_with_aim = not _touch
	_player = player


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if new_value > _health_bar.max_value:
		_health_bar.max_value = new_value
	_health_bar.value = new_value
	_health_text.text = "%d/%d" % [_health_bar.value, _health_bar.max_value]
	if new_value < old_value:
		_tint_anim.play(&"Hurt")
	_blood_vignette.visible = new_value < _health_bar.max_value * 0.34


func _on_player_died(_who: int) -> void:
	($Controller as Control).hide()
	_tint_anim.play(&"Death")


func _on_weapon_changed(to: Weapon.Type) -> void:
	match to:
		Weapon.Type.LIGHT:
			_current_weapon_icon.texture = _light_weapon_icon.texture
			(_current_weapon_icon.material as ShaderMaterial).set_shader_parameter(
					&"color",
					(_light_weapon_icon.material as ShaderMaterial).get_shader_parameter(&"color")
			)
		Weapon.Type.HEAVY:
			_current_weapon_icon.texture = _heavy_weapon_icon.texture
			(_current_weapon_icon.material as ShaderMaterial).set_shader_parameter(
					&"color",
					(_heavy_weapon_icon.material as ShaderMaterial).get_shader_parameter(&"color")
			)
		Weapon.Type.SUPPORT:
			_current_weapon_icon.texture = _support_weapon_icon.texture
			(_current_weapon_icon.material as ShaderMaterial).set_shader_parameter(
					&"color",
					(_support_weapon_icon.material as ShaderMaterial).get_shader_parameter(&"color")
			)
		Weapon.Type.MELEE:
			_current_weapon_icon.texture = _melee_weapon_icon.texture
			(_current_weapon_icon.material as ShaderMaterial).set_shader_parameter(
					&"color",
					(_melee_weapon_icon.material as ShaderMaterial).get_shader_parameter(&"color")
			)
	
	($Controller/TouchControls/Anchor/AdditionalButton as Node2D).visible = \
			_player.current_weapon.has_additional_button()


func _on_weapon_equipped(type: Weapon.Type, weapon_id: int) -> void:
	var weapon_icon: TextureRect
	var weapon_text: Label
	var weapon_data: WeaponData
	match type:
		Weapon.Type.LIGHT:
			weapon_icon = _light_weapon_icon
			weapon_text = $Controller/WeaponSelection/LightWeapon/Label
			if weapon_id >= 0:
				weapon_data = Globals.items_db.weapons_light[weapon_id]
		Weapon.Type.HEAVY:
			weapon_icon = _heavy_weapon_icon
			weapon_text = $Controller/WeaponSelection/HeavyWeapon/Label
			if weapon_id >= 0:
				weapon_data = Globals.items_db.weapons_heavy[weapon_id]
		Weapon.Type.SUPPORT:
			weapon_icon = _support_weapon_icon
			weapon_text = $Controller/WeaponSelection/SupportWeapon/Label
			if weapon_id >= 0:
				weapon_data = Globals.items_db.weapons_support[weapon_id]
		Weapon.Type.MELEE:
			weapon_icon = _melee_weapon_icon
			weapon_text = $Controller/WeaponSelection/MeleeWeapon/Label
			if weapon_id >= 0:
				weapon_data = Globals.items_db.weapons_melee[weapon_id]
	
	if weapon_id < 0:
		weapon_icon.texture = null
		weapon_text.text = "Нет оружия"
		if type == _player.current_weapon_type:
			_current_weapon_icon.texture = null
			_ammo_text.text = "Нет оружия"
		return
	
	weapon_icon.texture = load(weapon_data.image_path)
	(weapon_icon.material as ShaderMaterial).set_shader_parameter(
			&"color",
			ItemsDB.RARITY_COLORS[weapon_data.rarity],
	)
	weapon_text.text = weapon_data.name


func _on_ammo_text_updated(text: String) -> void:
	_ammo_text.text = text
