extends Control


@export_node_path("VirtualJoystick") var joystick_path: NodePath
@export var id: String
var _deadzone: float
var _scale: float
var _mode: VirtualJoystick.JoystickMode
@onready var _joystick: VirtualJoystick = get_node(joystick_path)


func _ready() -> void:
	_deadzone = Globals.get_controls_float("%s_joystick_deadzone" % id)
	_scale = Globals.get_controls_float("%s_joystick_scale" % id)
	_mode = Globals.get_controls_int("%s_joystick_mode" % id) as VirtualJoystick.JoystickMode
	_joystick.scale = Vector2.ONE * _scale
	($SettingsPanel/VBox/Deadzone/DeadzoneSlider as HSlider).value = _deadzone
	($SettingsPanel/VBox/Scale/ScaleSlider as HSlider).value = _scale
	($SettingsPanel/VBox/Mode/ModeOptions as OptionButton).selected = _mode


func _process(_delta: float) -> void:
	_joystick.global_position = global_position + size * (1.0 - _scale) / 2


func _draw() -> void:
	draw_circle(size / 2, _deadzone * _scale, Color.RED, false, 4.0, true)


func _on_controls_save_requested() -> void:
	Globals.set_controls_float("%s_joystick_deadzone" % id, _deadzone)
	Globals.set_controls_float("%s_joystick_scale" % id, _scale)
	Globals.set_controls_int("%s_joystick_mode" % id, _mode)


func _on_deadzone_slider_value_changed(value: float) -> void:
	_deadzone = value
	queue_redraw()


func _on_scale_slider_value_changed(value: float) -> void:
	_scale = value
	_joystick.scale = Vector2.ONE * value
	queue_redraw()


func _on_mode_options_item_selected(index: int) -> void:
	_mode = index as VirtualJoystick.JoystickMode
