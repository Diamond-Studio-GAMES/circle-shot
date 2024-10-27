extends Control


const MIN_AIM_DIRECTION_LENGTH := 0.1
const DEFAULT_WEAPON_BG_COLOR := Color(1.0, 1.0, 1.0, 0.5)
const SELECTED_WEAPON_BG_COLOR := Color.WHITE

var aim_deadzone := 60.0
var aim_max_at_distance := 260.0
var sneak_multiplier := 0.5
var change_weapon_deadzone := 32.0
var show_weapons_time := 0.4
var input_method: Main.InputMethod

var _player: Player

var _moving_left := false
var _moving_right := false
var _moving_up := false
var _moving_down := false
var _shooting := false
var _showing_aim := false
var _follow_mouse := true
var _aim_zone: float

var _touch_index: int = -1
var _touch_timer := 0.0
var _touch_start_position: Vector2
var _weapon_selection_tween: Tween

@onready var _health_bar: TextureProgressBar = $Controller/HealthBar
@onready var _health_text: Label = $Controller/HealthBar/Label
@onready var _blood_vignette: TextureRect = $Controller/BloodVignette
@onready var _tint_anim: AnimationPlayer = $PlayerTint/AnimationPlayer

@onready var _current_weapon: TextureRect = $Controller/CurrentWeapon
@onready var _current_weapon_icon: TextureRect = $Controller/CurrentWeapon/Icon
@onready var _light_weapon_icon: TextureRect = $Controller/WeaponSelection/LightWeaponIcon
@onready var _heavy_weapon_icon: TextureRect = $Controller/WeaponSelection/HeavyWeaponIcon
@onready var _support_weapon_icon: TextureRect = $Controller/WeaponSelection/SupportWeaponIcon
@onready var _melee_weapon_icon: TextureRect = $Controller/WeaponSelection/MeleeWeaponIcon
@onready var _ammo_text: Label = $Controller/CurrentWeapon/Label

@onready var _weapon_selection: Control = $Controller/WeaponSelection
@onready var _weapon_selection_bg_light: TextureRect = $Controller/WeaponSelection/BGLight
@onready var _weapon_selection_bg_heavy: TextureRect = $Controller/WeaponSelection/BGHeavy
@onready var _weapon_selection_bg_support: TextureRect = $Controller/WeaponSelection/BGSupport
@onready var _weapon_selection_bg_melee: TextureRect = $Controller/WeaponSelection/BGMelee

@onready var _skill: TextureProgressBar = $Controller/Skill
@onready var _skill_count: Label = $Controller/Skill/Count

@onready var _move_joystick: VirtualJoystick = $Controller/TouchControls/MoveVirtualJoystick
@onready var _aim_joystick: VirtualJoystick = $Controller/TouchControls/AimVirtualJoystick
@onready var _shoot_area: TouchScreenButton = $Controller/TouchControls/ShootArea

@onready var _center: Control = $Center


func _ready() -> void:
	input_method = Globals.get_controls_int("input_method") as Main.InputMethod
	
	match input_method:
		Main.InputMethod.KEYBOARD_AND_MOUSE:
			_aim_zone = aim_max_at_distance - aim_deadzone
			_follow_mouse = Globals.get_controls_bool("follow_mouse")
			($Controller/TouchControls as Control).hide()
			($Controller/Skill as Control).position = ($Controller/PCSkill as Control).position
			($Controller/CurrentWeapon as Control).position = \
					($Controller/PCCurrentWeapon as Control).position
			($Controller/Skill/TouchScreenButton as Node2D).hide()


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	
	_update_skill()
	match input_method:
		Main.InputMethod.TOUCH:
			_process_touch_input_method(delta)
		Main.InputMethod.KEYBOARD_AND_MOUSE:
			_process_keyboard_and_mouse_input_method()


func _input(event: InputEvent) -> void:
	match input_method:
		Main.InputMethod.TOUCH:
			_touch_input(event)


func _unhandled_input(event: InputEvent) -> void:
	match input_method:
		Main.InputMethod.KEYBOARD_AND_MOUSE:
			_unhandled_keyboard_and_mouse_input(event)


func select_weapon(type: Weapon.Type) -> void:
	if is_instance_valid(_player):
		_player.try_change_weapon(type)


func reload() -> void:
	if is_instance_valid(_player):
		_player.try_reload_weapon()


func additional_button() -> void:
	if is_instance_valid(_player):
		_player.try_use_additional_button_weapon()


func use_skill() -> void:
	if is_instance_valid(_player):
		_player.try_use_skill()


func open_weapon_selection() -> void:
	_weapon_selection.show()
	if is_instance_valid(_weapon_selection_tween):
		_weapon_selection_tween.kill()
	_weapon_selection_tween = create_tween()
	_weapon_selection_tween.tween_property(_weapon_selection, ^":modulate", Color.WHITE, 0.3)


func close_weapon_selection() -> void:
	if is_instance_valid(_weapon_selection_tween):
		_weapon_selection_tween.kill()
	_weapon_selection_tween = create_tween()
	_weapon_selection_tween.tween_property(_weapon_selection, ^":modulate", Color.TRANSPARENT, 0.2)
	_weapon_selection_tween.tween_callback(_weapon_selection.hide)


func _touch_input(event: InputEvent) -> void:
	var touch_event := event as InputEventScreenTouch
	if touch_event:
		if touch_event.pressed:
			if _touch_index >= 0:
				return
			if not _is_point_inside_of_control(touch_event.position, _current_weapon):
				return
			_touch_index = touch_event.index
			_touch_start_position = touch_event.position
			_touch_timer = 0.0
		else:
			if touch_event.index != _touch_index:
				return
			_touch_index = -1
			var new_type: Weapon.Type = \
					_get_weapon_type_from_vector(touch_event.position - _touch_start_position)
			match new_type:
				Weapon.Type.INVALID:
					reload()
				Weapon.Type.LIGHT:
					select_weapon(Weapon.Type.LIGHT)
				Weapon.Type.HEAVY:
					select_weapon(Weapon.Type.HEAVY)
				Weapon.Type.SUPPORT:
					select_weapon(Weapon.Type.SUPPORT)
				Weapon.Type.MELEE:
					select_weapon(Weapon.Type.MELEE)
			
			if _weapon_selection.visible:
				close_weapon_selection()
		return
	
	var drag_event := event as InputEventScreenDrag
	if drag_event:
		if drag_event.index != _touch_index:
			return
		_weapon_selection_bg_light.self_modulate = DEFAULT_WEAPON_BG_COLOR
		_weapon_selection_bg_heavy.self_modulate = DEFAULT_WEAPON_BG_COLOR
		_weapon_selection_bg_support.self_modulate = DEFAULT_WEAPON_BG_COLOR
		_weapon_selection_bg_melee.self_modulate = DEFAULT_WEAPON_BG_COLOR
		match _get_weapon_type_from_vector(drag_event.position - _touch_start_position):
			Weapon.Type.LIGHT:
				_weapon_selection_bg_light.self_modulate = SELECTED_WEAPON_BG_COLOR
			Weapon.Type.HEAVY:
				_weapon_selection_bg_heavy.self_modulate = SELECTED_WEAPON_BG_COLOR
			Weapon.Type.SUPPORT:
				_weapon_selection_bg_support.self_modulate = SELECTED_WEAPON_BG_COLOR
			Weapon.Type.MELEE:
				_weapon_selection_bg_melee.self_modulate = SELECTED_WEAPON_BG_COLOR


func _unhandled_keyboard_and_mouse_input(event: InputEvent) -> void:
	if event.is_action(&"move_left"):
		_moving_left = event.is_pressed()
	if event.is_action(&"move_right"):
		_moving_right = event.is_pressed()
	if event.is_action(&"move_up"):
		_moving_up = event.is_pressed()
	if event.is_action(&"move_down"):
		_moving_down = event.is_pressed()
	if event.is_action(&"shoot"):
		_shooting = event.is_pressed()
	if event.is_action(&"show_aim"):
		_showing_aim = event.is_pressed()
	
	if event.is_action_pressed(&"show_weapons"):
		if ($Controller/WeaponSelection as Control).visible:
			close_weapon_selection()
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
	elif event.is_action_pressed(&"use_skill"):
		use_skill()


func _process_touch_input_method(delta: float) -> void:
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
	
	if _touch_index >= 0:
		_touch_timer += delta
		if _touch_timer > show_weapons_time and not _weapon_selection.visible:
			open_weapon_selection()


func _process_keyboard_and_mouse_input_method() -> void:
	_player.entity_input.direction = (
			Vector2.LEFT * int(_moving_left) + Vector2.RIGHT * int(_moving_right)
			+ Vector2.UP * int(_moving_up) + Vector2.DOWN * int(_moving_down)
		).normalized()
	if Input.is_action_pressed(&"sneak"):
		_player.entity_input.direction *= sneak_multiplier
	
	_player.player_input.shooting = _shooting
	_player.player_input.showing_aim = _showing_aim
	
	if _follow_mouse or _showing_aim:
		var mouse_pos: Vector2 = _center.get_local_mouse_position()
		var mouse_distance: float = mouse_pos.length()
		if mouse_distance > aim_deadzone:
			_player.player_input.aim_direction = mouse_pos.normalized() * ((
					clampf(mouse_distance, aim_deadzone, aim_max_at_distance) - aim_deadzone
			) / _aim_zone * (1.0 - MIN_AIM_DIRECTION_LENGTH) + MIN_AIM_DIRECTION_LENGTH)
	_player.player_input.turn_with_aim = _follow_mouse or _showing_aim


func _update_skill() -> void:
	if not is_instance_valid(_player):
		return
	if not is_instance_valid(_player.skill):
		return
	
	if _player.skill_vars[0] > 0:
		if _player.skill_vars[1] > 0:
			_skill.value = 1.0 - _player.skill_vars[1] * 1.0 / _player.skill.use_cooldown
		else:
			_skill.value = 1
	else:
		_skill.value = 0
	_skill_count.text = str(_player.skill_vars[0])


func _is_point_inside_of_control(point: Vector2, control: Control) -> bool:
	var x: bool = point.x >= control.global_position.x \
			and point.x <= control.global_position.x \
			+ (control.size.x * control.get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= control.global_position.y \
			and point.y <= control.global_position.y \
			+ (control.size.y * control.get_global_transform_with_canvas().get_scale().y)
	return x and y


func _get_weapon_type_from_vector(vector: Vector2) -> Weapon.Type:
	if vector.length() < change_weapon_deadzone:
		return Weapon.Type.INVALID
	
	var angle: float = vector.angle()
	if angle <= PI / 4 and angle >= -PI / 4:
		# Смотрит вправо
		return Weapon.Type.LIGHT
	elif angle > PI / 4 and angle < PI / 4 * 3:
		# Смотрит вниз
		return Weapon.Type.HEAVY
	elif angle < -PI / 4 and angle > -PI / 4 * 3:
		# Смотрит вверх
		return Weapon.Type.SUPPORT
	else:
		# Смотрит влево
		return Weapon.Type.MELEE


func _on_local_player_created(player: Player) -> void:
	_health_bar.max_value = player.max_health
	_on_player_health_changed(player.max_health, player.max_health)
	
	_tint_anim.play(&"RESET")
	var tween: Tween = create_tween()
	($Controller as Control).show()
	($Controller as Control).modulate = Color.TRANSPARENT
	tween.tween_property($Controller as Control, ^":modulate", Color.WHITE, 0.5)
	
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	
	player.ammo_text_updated.connect(_on_ammo_text_updated)
	player.weapon_changed.connect(_on_weapon_changed)
	player.weapon_equipped.connect(_on_weapon_equipped)
	player.skill_equipped.connect(_on_skill_equipped)
	_player = player


func _on_player_health_changed(old_value: int, new_value: int) -> void:
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
			weapon_text = $Controller/WeaponSelection/LightWeaponName
			if weapon_id >= 0:
				weapon_data = Globals.items_db.weapons_light[weapon_id]
		Weapon.Type.HEAVY:
			weapon_icon = _heavy_weapon_icon
			weapon_text = $Controller/WeaponSelection/HeavyWeaponName
			if weapon_id >= 0:
				weapon_data = Globals.items_db.weapons_heavy[weapon_id]
		Weapon.Type.SUPPORT:
			weapon_icon = _support_weapon_icon
			weapon_text = $Controller/WeaponSelection/SupportWeaponName
			if weapon_id >= 0:
				weapon_data = Globals.items_db.weapons_support[weapon_id]
		Weapon.Type.MELEE:
			weapon_icon = _melee_weapon_icon
			weapon_text = $Controller/WeaponSelection/MeleeWeaponName
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


func _on_skill_equipped(skill_id: int) -> void:
	if skill_id < 0:
		_skill.hide()
		return
	_skill.show()
	
	($Controller/Skill/Icon as TextureRect).texture = \
			load(Globals.items_db.skills[skill_id].image_path)
	_update_skill()


func _on_ammo_text_updated(text: String) -> void:
	_ammo_text.text = text
