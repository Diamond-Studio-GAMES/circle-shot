class_name GrenadeProjectile
extends AnimatableBody2D

## Узел снаряда гранаты.

## Скорость снаряда гранаты.
@export var speed := 800.0
## Замедление снаряда гранаты.
@export var damping := 200.0
## Направление снаряда.
var direction: Vector2
var _current_speed: float
var _exploded := false
@onready var _anim: AnimationPlayer = $Grenade/AnimationPlayer


func _ready() -> void:
	_current_speed = speed


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	
	_current_speed -= damping * delta
	if _current_speed < 0.0:
		_current_speed = 0.0
	_anim.speed_scale = _current_speed / speed
	
	var collision: KinematicCollision2D = move_and_collide(_current_speed * direction * delta)
	if collision:
		direction = direction.bounce(collision.get_normal())


## То же, что и [method Node.queue_free], но может вызывается только на сервере.
func safe_free() -> void:
	if multiplayer.is_server():
		queue_free()


## Вызывается при истечении таймера взрыва.
func _explode() -> void:
	pass


func _on_explosion_timer_timeout() -> void:
	_exploded = true
	_explode()
