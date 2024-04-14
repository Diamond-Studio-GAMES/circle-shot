class_name Player
extends CharacterBody2D


const SPEED := 160.0
@export var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)
@onready var _head: Sprite2D = $Head
@onready var _player_input: PlayerInput


func _physics_process(_delta: float) -> void:
	velocity = _player_input.direction.normalized() * SPEED
	if velocity != Vector2.ZERO:
		_head.scale.x = -1 if velocity.x < 0 else 1
	move_and_slide()
