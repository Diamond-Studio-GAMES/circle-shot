extends "res://weapons/common/gun.gd"

@export var aim_zoom: Vector2
var _aim_visible_in_previous_frame := false
var _default_zoom: Vector2

func _ready() -> void:
	super()
	_default_zoom = get_viewport().get_camera_2d().zoom


func _process(delta: float) -> void:
	super(delta)
	if _aim_visible_in_previous_frame != _aim.visible:
		_aim_visible_in_previous_frame = _aim.visible
		var camera: Camera2D = get_viewport().get_camera_2d()
		var tween: Tween = camera.create_tween()
		tween.tween_property(camera, ^"zoom", aim_zoom if _aim.visible else _default_zoom, 0.2)


func _unmake_current() -> void:
	_aim_visible_in_previous_frame = false
	var camera: Camera2D = get_viewport().get_camera_2d()
	var tween: Tween = camera.create_tween()
	tween.tween_property(camera, ^"zoom", _default_zoom, 0.2)
