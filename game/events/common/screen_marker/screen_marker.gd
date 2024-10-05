extends Node2D


@export var margin := 120.0
@export var arrow_margin := 16.0

@onready var _marker: Node2D = $Visual/Marker
@onready var _icon: Sprite2D = $Visual/Marker/Icon
@onready var _arrow: Sprite2D = $Visual/Marker/Arrow
@onready var _arrow_icon: Sprite2D = $Visual/Marker/Arrow/Icon


func _process(_delta: float) -> void:
	var screen_pos: Vector2 = get_global_transform_with_canvas() * Vector2.ZERO
	var screen_size: Vector2 = get_viewport_rect().size
	var clamped_pos := Vector2(
			clampf(screen_pos.x, margin, screen_size.x - margin),
			clampf(screen_pos.y, margin, screen_size.y - margin)
	)
	if screen_pos.is_equal_approx(clamped_pos):
		_arrow.hide()
		_icon.show()
		_marker.position = screen_pos
	else:
		_arrow.show()
		_icon.hide()
		_arrow.rotation = (screen_pos - screen_size / 2).angle()
		_arrow_icon.global_rotation = 0.0
		_marker.position = Vector2(
				clampf(screen_pos.x, arrow_margin, screen_size.x - arrow_margin),
				clampf(screen_pos.y, arrow_margin, screen_size.y - arrow_margin)
		)
