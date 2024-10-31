extends Skill


@export_range(0.0, 1.0) var speed_boost := 0.15
@export_range(0.0, 1.0) var damage_boost := 0.1
@export_range(0.0, 1.0) var defense_boost := 0.1
@export var boost_duration := 5.0
@export var shake_amplitude := 32.0
@export var shake_duration := 0.6
var _use_effect_scene: PackedScene = preload("uid://c7rmbgdh6weme")
@onready var _timer: Timer = $Timer


func _use() -> void:
	var use_effect: Node2D = _use_effect_scene.instantiate()
	_player.visual.add_child(use_effect)
	
	_player.make_disarmed()
	_timer.start(1.25)
	await _timer.timeout
	if multiplayer.is_server():
		_player.add_effect.rpc(Effect.DEFENSE_CHANGE, boost_duration, [1.0 - defense_boost])
		_player.add_effect.rpc(Effect.SPEED_CHANGE, boost_duration, [1.0 + speed_boost])
		_player.add_effect.rpc(Effect.DAMAGE_CHANGE, boost_duration, [1.0 + damage_boost])
	if _player.is_local():
		var camera: SmartCamera = get_viewport().get_camera_2d()
		camera.shake(shake_amplitude, shake_duration)
	_timer.start(0.35)
	await _timer.timeout
	_player.unmake_disarmed()
