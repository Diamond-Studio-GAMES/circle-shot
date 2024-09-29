class_name GrenadeProjectile
extends AnimatableBody2D


@export var speed := 800.0
@export var damping := 200.0
var current_speed: float
var direction := Vector2.ZERO
var _exploded := false
@onready var _anim: AnimationPlayer = $Grenade/AnimationPlayer


func _ready() -> void:
	direction = Vector2.RIGHT.rotated(rotation)
	rotation = 0.0
	current_speed = speed


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	
	current_speed -= damping * delta
	if current_speed < 0.0:
		current_speed = 0.0
	_anim.speed_scale = current_speed / speed
	
	var collision: KinematicCollision2D = move_and_collide(current_speed * direction * delta)
	if collision:
		direction = direction.bounce(collision.get_normal())


func safe_free() -> void:
	if multiplayer.is_server():
		queue_free()


func _explode() -> void:
	pass


func _on_explosion_timer_timeout() -> void:
	_exploded = true
	_explode()
