extends Node

@export var id: String
var touch_index: int = -1
@onready var _parent: Control = get_parent()

func _ready() -> void:
	_parent.mouse_filter = Control.MOUSE_FILTER_STOP
	if not _parent.gui_input.is_connected(_on_parent_gui_input):
		_parent.gui_input.connect(_on_parent_gui_input)


func _on_parent_gui_input(event: InputEvent) -> void:
	var st := event as InputEventScreenTouch
	if st:
		if st.pressed and touch_index == -1:
			touch_index = st.index
		elif not st.pressed and touch_index > -1:
			touch_index = -1
	
	var sg := event as InputEventScreenDrag
	if sg and sg.index == touch_index:
		_parent.global_position += sg.relative
		var viewport_size: Vector2 = _parent.get_viewport_rect().size
		var center_pos: Vector2 = _parent.position + _parent.size / 2
		if center_pos.y < viewport_size.y * 0.25:
			if center_pos.x < viewport_size.x * 0.313:
				_parent.set_anchors_preset(Control.PRESET_TOP_LEFT)
			elif center_pos.x < viewport_size.x * 0.687:
				_parent.set_anchors_preset(Control.PRESET_CENTER_TOP)
			else:
				_parent.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		elif center_pos.y < viewport_size.y * 0.65:
			if center_pos.x < viewport_size.x * 0.313:
				_parent.set_anchors_preset(Control.PRESET_CENTER_LEFT)
			elif center_pos.x < viewport_size.x * 0.687:
				_parent.set_anchors_preset(Control.PRESET_CENTER)
			else:
				_parent.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		else:
			if center_pos.x < viewport_size.x * 0.313:
				_parent.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			elif center_pos.x < viewport_size.x * 0.687:
				_parent.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			else:
				_parent.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)


func _on_controls_save_requested() -> void:
	Globals.set_controls_int("anchors_preset_%s" % id, _get_preset())
	Globals.set_controls_vector2(
			"offsets_lt_%s" % id, Vector2(_parent.offset_left, _parent.offset_top)
	)
	Globals.set_controls_vector2(
			"offsets_rb_%s" % id, Vector2(_parent.offset_right, _parent.offset_bottom)
	)


func _get_preset() -> Control.LayoutPreset:
	var c: Control = _parent
	if is_equal_approx(c.anchor_left, 0.0) and is_equal_approx(c.anchor_top, 0.0) \
			and is_equal_approx(c.anchor_right, 0.0) and is_equal_approx(c.anchor_bottom, 0.0):
		return Control.PRESET_TOP_LEFT
	if is_equal_approx(c.anchor_left, 1.0) and is_equal_approx(c.anchor_top, 0.0) \
			and is_equal_approx(c.anchor_right, 1.0) and is_equal_approx(c.anchor_bottom, 0.0):
		return Control.PRESET_TOP_RIGHT
	if is_equal_approx(c.anchor_left, 1.0) and is_equal_approx(c.anchor_top, 1.0) \
			and is_equal_approx(c.anchor_right, 1.0) and is_equal_approx(c.anchor_bottom, 1.0):
		return Control.PRESET_BOTTOM_RIGHT
	if is_equal_approx(c.anchor_left, 0.0) and is_equal_approx(c.anchor_top, 1.0) \
			and is_equal_approx(c.anchor_right, 0.0) and is_equal_approx(c.anchor_bottom, 1.0):
		return Control.PRESET_BOTTOM_LEFT
	
	if is_equal_approx(c.anchor_left, 0.0) and is_equal_approx(c.anchor_top, 0.5) \
			and is_equal_approx(c.anchor_right, 0.0) and is_equal_approx(c.anchor_bottom, 0.5):
		return Control.PRESET_CENTER_LEFT
	if is_equal_approx(c.anchor_left, 0.5) and is_equal_approx(c.anchor_top, 0.0) \
			and is_equal_approx(c.anchor_right, 0.5) and is_equal_approx(c.anchor_bottom, 0.0):
		return Control.PRESET_CENTER_TOP
	if is_equal_approx(c.anchor_left, 1.0) and is_equal_approx(c.anchor_top, 0.5) \
			and is_equal_approx(c.anchor_right, 1.0) and is_equal_approx(c.anchor_bottom, 0.5):
		return Control.PRESET_CENTER_RIGHT
	if is_equal_approx(c.anchor_left, 0.5) and is_equal_approx(c.anchor_top, 1.0) \
			and is_equal_approx(c.anchor_right, 0.5) and is_equal_approx(c.anchor_bottom, 1.0):
		return Control.PRESET_CENTER_BOTTOM
	
	if is_equal_approx(c.anchor_left, 0.5) and is_equal_approx(c.anchor_top, 0.5) \
			and is_equal_approx(c.anchor_right, 0.5) and is_equal_approx(c.anchor_bottom, 0.5):
		return Control.PRESET_CENTER
	
	return Control.PRESET_FULL_RECT
