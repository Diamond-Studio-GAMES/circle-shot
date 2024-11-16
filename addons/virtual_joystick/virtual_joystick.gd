class_name VirtualJoystick
extends Control

## A simple virtual joystick for touchscreens, with useful options.

## Emits when joystick is released. [param output] contains joystick's output before resetting.
signal released(output: Vector2)

enum VisibilityMode {
	ALWAYS, ## The joystick is always visible.
	TOUCHSCREEN_ONLY, ## The joystick is visible on touchscreens only.
	WHEN_TOUCHED, ## The joystick is visible only when touched.
}
enum JoystickMode {
	FIXED, ## The joystick doesn't move.
	DYNAMIC, ## Every time the joystick area is pressed, the joystick position is set on the touched position.
	FOLLOWING, ## When the finger moves outside the joystick area, the joystick will follow it.
}

## Sets the joystick mode. See [enum VirtualJoystick.JoystickMode].
@export var joystick_mode := JoystickMode.FIXED
## Sets the visibility mode. See [enum VirtualJoystick.VisibilityMode].
@export var visibility_mode := VisibilityMode.ALWAYS
## If the input is inside this range, the output is zero.
@export_range(0.0, 200.0) var deadzone_size := 10.0
## The max distance the tip can reach.
@export_range(0.0, 500.0) var clampzone_size: float = 75.0
@export_group("Appearance")
## The color of the tip when the joystick is pressed.
@export var pressed_color := Color.GRAY
## Texture of joystick base.
@export var base_texture: Texture2D
## Texture of joystick moving tip.
@export var tip_texture: Texture2D
@export_group("Actions")
## If [code]true[/code], the joystick uses Input Actions (Project -> Project Settings -> Input Map).
@export var use_input_actions := false
@export_group("Actions", "action_")
@export var action_left := "ui_left"
@export var action_right := "ui_right"
@export var action_up := "ui_up"
@export var action_down := "ui_down"

## The joystick output.
var output := Vector2.ZERO

var _touch_index: int = -1
var _pressed := false
@onready var _base: TextureRect = $Base
@onready var _tip: TextureRect = $Base/Tip
@onready var _base_default_position: Vector2 = _base.position
@onready var _tip_default_position: Vector2 = _tip.position
@onready var _default_color: Color = _tip.modulate


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available() and visibility_mode == VisibilityMode.TOUCHSCREEN_ONLY:
		set_process_input(false)
		hide()
	if visibility_mode == VisibilityMode.WHEN_TOUCHED:
		hide()
	_base.texture = base_texture
	_tip.texture = tip_texture


## Returns [code]true[/code] if the joystick is receiving inputs.
func is_pressed() -> bool:
	return _pressed


func _input(event: InputEvent) -> void:
	var touch_event := event as InputEventScreenTouch
	if touch_event:
		if touch_event.pressed:
			if _is_point_inside_joystick_area(touch_event.position) and _touch_index == -1:
				if (
						joystick_mode == JoystickMode.DYNAMIC
						or joystick_mode == JoystickMode.FOLLOWING
						or (joystick_mode == JoystickMode.FIXED
						and _is_point_inside_base(touch_event.position))
				):
					if joystick_mode == JoystickMode.DYNAMIC or joystick_mode == JoystickMode.FOLLOWING:
						_move_base(touch_event.position)
					if visibility_mode == VisibilityMode.WHEN_TOUCHED:
						show()
					_touch_index = touch_event.index
					_tip.modulate = pressed_color
					_update_joystick(touch_event.position)
					get_viewport().set_input_as_handled()
		elif touch_event.index == _touch_index:
			_reset()
			if visibility_mode == VisibilityMode.WHEN_TOUCHED:
				hide()
			get_viewport().set_input_as_handled()
		return
	var drag_event := event as InputEventScreenDrag
	if drag_event:
		if drag_event.index == _touch_index:
			_update_joystick(drag_event.position)
			get_viewport().set_input_as_handled()


func _move_base(new_position: Vector2) -> void:
	_base.global_position = new_position - _base.pivot_offset * get_global_transform_with_canvas().get_scale()


func _move_tip(new_position: Vector2) -> void:
	_tip.global_position = new_position - _tip.pivot_offset * _base.get_global_transform_with_canvas().get_scale()


func _is_point_inside_joystick_area(point: Vector2) -> bool:
	var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y


func _get_base_radius() -> Vector2:
	return _base.size * _base.get_global_transform_with_canvas().get_scale() / 2


func _is_point_inside_base(point: Vector2) -> bool:
	var _base_radius: Vector2 = _get_base_radius()
	var center: Vector2 = _base.global_position + _base_radius
	var vector: Vector2 = point - center
	return vector.length_squared() <= _base_radius.x * _base_radius.x


func _update_joystick(touch_position: Vector2) -> void:
	var _base_radius: Vector2 = _get_base_radius()
	var center: Vector2 = _base.global_position + _base_radius
	var vector: Vector2 = touch_position - center
	vector = vector.limit_length(clampzone_size)
	
	if joystick_mode == JoystickMode.FOLLOWING and touch_position.distance_to(center) > clampzone_size:
		_move_base(touch_position - vector)
	_move_tip(center + vector)
	if vector.length_squared() > deadzone_size * deadzone_size:
		_pressed = true
		output = (vector - (vector.normalized() * deadzone_size)) / (clampzone_size - deadzone_size)
	else:
		_pressed = false
		output = Vector2.ZERO
	
	if use_input_actions:
		if output.x > 0:
			Input.action_release(action_left)
			Input.action_press(action_right, output.x)
		else:
			Input.action_release(action_right)
			Input.action_press(action_left, -output.x)

		if output.y > 0:
			Input.action_release(action_up)
			Input.action_press(action_down, output.y)
		else:
			Input.action_release(action_down)
			Input.action_press(action_up, -output.y)


func _reset() -> void:
	released.emit(output)
	_pressed = false
	output = Vector2.ZERO
	_touch_index = -1
	_tip.modulate = _default_color
	_base.position = _base_default_position
	_tip.position = _tip_default_position
	if use_input_actions:
		for action: String in [action_left, action_right, action_down, action_up]:
			Input.action_release(action)
