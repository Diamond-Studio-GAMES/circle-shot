extends Node

@export var id: String

func _ready() -> void:
	if Globals.get_controls_int("input_method") != Main.InputMethod.TOUCH:
		return
	
	var parent: Control = get_parent()
	
	var anchors_preset: Control.LayoutPreset = \
			Globals.get_controls_int("anchors_preset_%s" % id) as Control.LayoutPreset
	parent.set_anchors_preset(anchors_preset)
	
	var offsets_lt: Vector2 = Globals.get_controls_vector2("offsets_lt_%s" % id)
	var offsets_rb: Vector2 = Globals.get_controls_vector2("offsets_rb_%s" % id)
	parent.offset_left = offsets_lt.x
	parent.offset_top = offsets_lt.y
	parent.offset_right = offsets_rb.x
	parent.offset_bottom = offsets_rb.y
