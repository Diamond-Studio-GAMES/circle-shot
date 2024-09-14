extends AnimatableBody2D


@export var speed: float = 800.0
var direction := Vector2.ZERO
var _exploded := false


func _ready() -> void:
	direction = Vector2.RIGHT.rotated(rotation)
	rotation = 0.0


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	move_and_collide(speed * direction * delta)


func _on_explosion_timer_timeout() -> void:
	_exploded = true
	($Explosion/AnimationPlayer as AnimationPlayer).play("Explode")


func _free() -> void:
	if multiplayer.is_server():
		queue_free()
