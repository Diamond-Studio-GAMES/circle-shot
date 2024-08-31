extends Attack

@export var speed: float = 1280.0
@export var hit_vfx: PackedScene
var direction := Vector2.ZERO

func _ready() -> void:
	direction = Vector2.RIGHT.rotated(rotation)
	var tween := create_tween()
	tween.tween_property($Sprite2D as Node2D, ^"scale:x", 1.0, 0.25).from(0.1)


func _physics_process(delta: float) -> void:
	position += speed * direction * delta


func _create_vfx() -> void:
	var vfx_parent: Node = get_tree().get_first_node_in_group("VFXParent")
	if not vfx_parent:
		return
	var vfx: Node2D = hit_vfx.instantiate()
	vfx.position = position
	vfx_parent.add_child(vfx)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player:
		if player.team == team:
			return
		deal_damage(player)
	queue_free()


func _on_timer_timeout() -> void:
	if multiplayer.is_server():
		queue_free()
