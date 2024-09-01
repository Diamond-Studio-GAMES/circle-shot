extends Attack

@export var speed := 1280.0
@export var hit_vfx: PackedScene
var direction := Vector2.ZERO

func _ready() -> void:
	direction = Vector2.RIGHT.rotated(rotation)
	var tween: Tween = create_tween()
	tween.tween_property($Sprite2D as Node2D, ^"scale:x", 1.0, 0.25).from(0.1)


func _physics_process(delta: float) -> void:
	position += speed * direction * delta


func _create_vfx(pos: Vector2) -> void:
	var vfx_parent: Node = get_tree().get_first_node_in_group("VFXParent")
	if not is_instance_valid(vfx_parent):
		return
	var vfx: Node2D = hit_vfx.instantiate()
	vfx.global_position = pos
	vfx_parent.add_child(vfx)


func _on_ray_detector_hit(where: Vector2) -> void:
	speed = 0
	hide()
	($RayDetector as RayCast2D).enabled = false
	_create_vfx(where)


func _on_timer_timeout() -> void:
	if multiplayer.is_server():
		queue_free()
