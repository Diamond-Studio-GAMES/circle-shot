class_name Player
extends CharacterBody2D


const SPEED := 480.0
var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)
var team := 0
var player_name := "Колобок"
var weapons_data: Array
@onready var camera_remote_transform: RemoteTransform2D = $CameraRemoteTransform
@onready var _visual: Node2D = $Visual
@onready var _player_input: PlayerInput = $PlayerInput


func _ready() -> void:
	($Name/Label as Label).text = player_name


func _physics_process(_delta: float) -> void:
	velocity = _player_input.direction.normalized() * SPEED
	if velocity != Vector2.ZERO:
		_visual.scale.x = -1 if velocity.x < 0 else 1
	move_and_slide()
