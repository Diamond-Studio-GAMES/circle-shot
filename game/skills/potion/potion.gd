extends Skill

@export var heal_amount: int = 60
var _use_effect_scene: PackedScene = preload("uid://c1jxj44vodfa7")
@onready var _timer: Timer = $Timer

func _use() -> void:
	var use_effect: Node2D = _use_effect_scene.instantiate()
	_player.visual.add_child(use_effect)
	if _player.is_local():
		(use_effect.get_node(^"Tint/AnimationPlayer") as AnimationPlayer).play(&"Tint")
	
	_player.make_disarmed()
	if multiplayer.is_server():
		_timer.start(1.25)
		await _timer.timeout
		_player.heal(ceili(heal_amount / 3.0))
		_timer.start(0.2)
		await _timer.timeout
		_player.heal(roundi(heal_amount / 3.0))
		_timer.start(0.2)
		await _timer.timeout
		_player.heal(floori(heal_amount / 3.0))
		_timer.start(1.05)
		await _timer.timeout
	else:
		_timer.start(2.5)
		await _timer.timeout
	_player.unmake_disarmed()


func _can_use() -> bool:
	return _player.current_health != _player.max_health
