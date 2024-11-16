extends Control


const MIN_AIM_DIRECTION_LENGTH := 0.1
const DEFAULT_WEAPON_BG_COLOR := Color(1.0, 1.0, 1.0, 0.5)
const SELECTED_WEAPON_BG_COLOR := Color.WHITE
const MIN_VIBRATION_DURATION_MS: int = 100
const MAX_VIBRATION_DURATION_MS: int = 500
const MIN_VIBRATION_AMPLITUDE := 0.1
const MAX_VIBRATION_AMPLITUDE := 0.5

var input_method: Main.InputMethod
var vibration_enabled: bool

var aim_deadzone: float
var aim_zone: float
var sneak_multiplier: float
var follow_mouse: bool

var joystick_fire: bool
var change_weapon_deadzone := 32.0
var show_weapons_time := 0.4
var square_joystick: bool

var _player: Player

var _moving_left := false
var _moving_right := false
var _moving_up := false
var _moving_down := false
var _shooting := false
var _showing_aim := false
var _aim_zone: float

var _touch_index: int = -1
var _touch_timer := 0.0
var _touch_start_position: Vector2
var _weapon_selection_tween: Tween

var _health_immediate_bar_tween: Tween
var _health_bar_tween: Tween

@onready var _health_bar: TextureProgressBar = $Controller/HealthBar/Health
@onready var _health_immediate_bar: TextureProgressBar = $Controller/HealthBar/HealthImmediate
@onready var _health_text: Label = $Controller/HealthBar/Label
@onready var _blood_vignette: TextureRect = $Controller/BloodVignette
@onready var _tint_anim: AnimationPlayer = $PlayerTint/AnimationPlayer

@onready var _current_weapon: TextureRect = $Controller/CurrentWeapon
@onready var _current_weapon_icon: TextureRect = $Controller/CurrentWeapon/Icon
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
@onready var _single_shot_timer: Timer = $SingleShotTimer

@onready var _center: Control = $Center


func _ready() -> void:
	input_method = Globals.get_controls_int("input_method") as Main.InputMethod
	vibration_enabled = Globals.get_setting_bool("vibration_damage")
	
	match input_method:
		Main.InputMethod.KEYBOARD_AND_MOUSE:
			($Controller/TouchControls as Control).hide()
			($Controller/Skill/TouchScreenButton as Node2D).hide()
			follow_mouse = Globals.get_controls_bool("follow_mouse")
			sneak_multiplier = Globals.get_controls_float("sneak_multiplier")
			var smallest_side: float = minf(get_viewport_rect().size.x, get_viewport_rect().size.y)
			aim_deadzone = Globals.get_controls_float("aim_deadzone") * smallest_side / 2
			aim_zone = Globals.get_controls_float("aim_zone") * smallest_side / 2
			_aim_zone = aim_zone - aim_deadzone
		Main.InputMethod.TOUCH:
			joystick_fire = Globals.get_controls_bool("joystick_fire")
			if joystick_fire:
				_aim_joystick.released.connect(_on_aim_joystick_released)
			square_joystick = Globals.get_controls_bool("square_joystick")
			
			_move_joystick.scale = Vector2.ONE * Globals.get_controls_float("move_joystick_scale")
			_move_joystick.deadzone_size = Globals.get_controls_float("move_joystick_deadzone")
			_move_joystick.clampzone_size *= Globals.get_controls_float("move_joystick_scale")
			_move_joystick.deadzone_size *= Globals.get_controls_float("move_joystick_scale")
			_move_joystick.joystick_mode = \
					Globals.get_controls_int("move_joystick_mode") as VirtualJoystick.JoystickMode
			
			_aim_joystick.scale = Vector2.ONE * Globals.get_controls_float("aim_joystick_scale")
			_aim_joystick.deadzone_size = Globals.get_controls_float("aim_joystick_deadzone")
			_aim_joystick.clampzone_size *= Globals.get_controls_float("aim_joystick_scale")
			_aim_joystick.deadzone_size *= Globals.get_controls_float("aim_joystick_scale")
			_aim_joystick.joystick_mode = \
					Globals.get_controls_int("aim_joystick_mode") as VirtualJoystick.JoystickMode
			
			(_shoot_area.shape as RectangleShape2D).size = \
					Globals.get_controls_vector2("shoot_area")
			_shoot_area.position = Globals.get_controls_vector2("shoot_area") / 2


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
			if _touch_index >= 0 \
					or not _is_point_inside_of_control(touch_event.position, _current_weapon):
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
	if not drag_event or drag_event.index != _touch_index:
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
	if event.is_action_pressed(&"weapon_light"):
		select_weapon(Weapon.Type.LIGHT)
	if event.is_action_pressed(&"weapon_heavy"):
		select_weapon(Weapon.Type.HEAVY)
	if event.is_action_pressed(&"weapon_support"):
		select_weapon(Weapon.Type.SUPPORT)
	if event.is_action_pressed(&"weapon_melee"):
		select_weapon(Weapon.Type.MELEE)
	if event.is_action_pressed(&"reload"):
		reload()
	if event.is_action_pressed(&"additional_button"):
		additional_button()
	if event.is_action_pressed(&"use_skill"):
		use_skill()


func _process_touch_input_method(delta: float) -> void:
	var direction: Vector2 = _move_joystick.output
	if square_joystick:
		_player.entity_input.direction = direction.normalized() * direction.length_squared()
	else:
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
	
	if not joystick_fire:
		_player.player_input.shooting = _shoot_area.is_pressed()
	else:
		if not is_instance_valid(_player.current_weapon) \
				or not _player.current_weapon.shoot_on_joystick_release:
			_player.player_input.shooting = not _aim_joystick.output.is_zero_approx()
	
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
	
	if follow_mouse or _showing_aim:
		var mouse_pos: Vector2 = _center.get_local_mouse_position()
		var mouse_distance: float = mouse_pos.length()
		if mouse_distance > aim_deadzone:
			_player.player_input.aim_direction = mouse_pos.normalized() * ((
					clampf(mouse_distance, aim_deadzone, aim_zone) - aim_deadzone
			) / _aim_zone * (1.0 - MIN_AIM_DIRECTION_LENGTH) + MIN_AIM_DIRECTION_LENGTH)
	_player.player_input.turn_with_aim = follow_mouse or _showing_aim


func _update_skill() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_player.skill):
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


func _change_health_bar_glow(glow: float) -> void:
	(_health_bar.material as ShaderMaterial).set_shader_parameter(&"power", glow)


func _on_local_player_created(player: Player) -> void:
	_health_bar.max_value = player.max_health
	_health_immediate_bar.max_value = player.max_health
	_on_player_health_changed(player.max_health, player.max_health)
	_health_bar_tween.kill()
	_change_health_bar_glow(0.0) # Убрать эффект отхила
	
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
		if is_instance_valid(_health_immediate_bar_tween):
			_health_immediate_bar_tween.kill()
		_health_immediate_bar_tween = create_tween()
		if _health_immediate_bar.value < old_value:
			_health_immediate_bar.value = old_value
		_health_bar_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		_health_immediate_bar_tween.tween_interval(0.3)
		_health_immediate_bar_tween.tween_property(_health_immediate_bar, ^":value", new_value, 0.5)
		
		var change_ratio: float = (old_value - new_value) / float(_player.max_health)
		if vibration_enabled:
			Input.vibrate_handheld(
					MIN_VIBRATION_DURATION_MS +
					roundi((MAX_VIBRATION_DURATION_MS - MIN_VIBRATION_DURATION_MS) * change_ratio),
					MIN_VIBRATION_AMPLITUDE +
					roundi((MAX_VIBRATION_AMPLITUDE - MIN_VIBRATION_AMPLITUDE) * change_ratio)
			)
	else:
		if is_instance_valid(_health_bar_tween):
			_health_bar_tween.kill()
		_health_bar_tween = create_tween()
		_health_bar_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		_health_bar_tween.tween_method(_change_health_bar_glow, 1.0, 0.0, 1.0)
	
	_blood_vignette.visible = new_value < _health_bar.max_value * 0.34


func _on_player_died(_who: int) -> void:
	($Controller as Control).hide()
	_tint_anim.play(&"Death")
	if vibration_enabled:
		Input.vibrate_handheld(MAX_VIBRATION_DURATION_MS, MAX_VIBRATION_AMPLITUDE)


func _on_weapon_changed(_to: Weapon.Type) -> void:
	if not is_instance_valid(_player.current_weapon):
		_current_weapon_icon.texture = null
		return
	
	_current_weapon_icon.texture = load(_player.current_weapon.data.image_path)
	(_current_weapon_icon.material as ShaderMaterial).set_shader_parameter(
			&"color",
			ItemsDB.RARITY_COLORS[_player.current_weapon.data.rarity],
	)
	
	($Controller/TouchControls/Anchor/AdditionalButton as Node2D).visible = \
			_player.current_weapon.has_additional_button()


func _on_weapon_equipped(type: Weapon.Type, data: WeaponData) -> void:
	var weapon_icon: TextureRect
	var weapon_text: Label
	match type:
		Weapon.Type.LIGHT:
			weapon_icon = $Controller/WeaponSelection/LightWeaponIcon
			weapon_text = $Controller/WeaponSelection/LightWeaponName
		Weapon.Type.HEAVY:
			weapon_icon = $Controller/WeaponSelection/HeavyWeaponIcon
			weapon_text = $Controller/WeaponSelection/HeavyWeaponName
		Weapon.Type.SUPPORT:
			weapon_icon = $Controller/WeaponSelection/SupportWeaponIcon
			weapon_text = $Controller/WeaponSelection/SupportWeaponName
		Weapon.Type.MELEE:
			weapon_icon = $Controller/WeaponSelection/MeleeWeaponIcon
			weapon_text = $Controller/WeaponSelection/MeleeWeaponName
	
	if not data:
		weapon_icon.texture = null
		weapon_text.text = "Нет оружия"
		return
	
	weapon_icon.texture = load(data.image_path)
	(weapon_icon.material as ShaderMaterial).set_shader_parameter(
			&"color",
			ItemsDB.RARITY_COLORS[data.rarity],
	)
	weapon_text.text = data.name


func _on_skill_equipped(data: SkillData) -> void:
	if not data:
		_skill.hide()
		return
	_skill.show()
	
	($Controller/Skill/Icon as TextureRect).texture = load(data.image_path)
	_update_skill()


func _on_ammo_text_updated(text: String) -> void:
	_ammo_text.text = text


func _on_aim_joystick_released(output: Vector2) -> void:
	if (
			is_instance_valid(_player) and is_instance_valid(_player.current_weapon) \
			and _player.current_weapon.shoot_on_joystick_release
			and not output.is_zero_approx()
	):
		_player.player_input.shooting = true
		_single_shot_timer.start()


func _on_single_shot_timer_timeout() -> void:
	if is_instance_valid(_player):
		_player.player_input.shooting = false
