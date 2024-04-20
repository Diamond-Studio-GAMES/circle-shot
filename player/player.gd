class_name Player
extends CharacterBody2D


signal health_changed(old_value: int, new_value: int)
signal killed(who: int, by: int)
const SPEED := 640.0
# Sync on start
var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)
var team := 0
var player_name := "Колобок"
var weapons_data: Array
var can_control := true
# State variables
var current_health := 100
var max_health := 100
var speed_multiplier := 1.0
@onready var remote_transform: RemoteTransform2D = $RemoteTransform
@onready var _visual: Node2D = $Visual
@onready var _player_input: PlayerInput = $PlayerInput


func _ready() -> void:
	($Name/Label as Label).text = player_name
	if player == multiplayer.get_unique_id():
		(get_tree().get_first_node_in_group("Game") as Game).set_local_player(self)
		($ControlIndicator as Node2D).show()
		($ControlIndicator as Node2D).self_modulate = Game.TEAM_COLORS[team]


func _physics_process(_delta: float) -> void:
	velocity = _player_input.direction.normalized() * SPEED * speed_multiplier * int(can_control)
	if velocity != Vector2.ZERO:
		_visual.scale.x = -1 if velocity.x < 0 else 1
	move_and_slide()


@rpc("call_local", "reliable", "authority", 1)
func set_health(health: int) -> void:
	if health <= 0:
		queue_free()
		return
	health_changed.emit(current_health, health)
	current_health = health
	if current_health > max_health:
		max_health = current_health


func damage(amount: int, by: int) -> void:
	if not multiplayer.is_server():
		return
	var new_health := clampi(current_health - amount, 0, max_health)
	if new_health <= 0:
		killed.emit(multiplayer.get_unique_id(), by)
	set_health.rpc(new_health)
