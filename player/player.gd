class_name Player
extends CharacterBody2D


const SPEED := 300.0
@export var movement := Vector2.ZERO
@onready var _head: Sprite2D = $Head


func _physics_process(_delta: float) -> void:
	velocity = movement
	if movement != Vector2.ZERO:
		_head.scale.x = -1 if movement.x < 0 else 1
	move_and_slide()
