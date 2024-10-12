class_name Skill
extends Node2D


@export var use_times: int = 2
@export var use_cooldown: int = 30
var _player: Player
var _cooldown_timer := 0.0


func _physics_process(delta: float) -> void:
	_cooldown_timer -= delta
	_player.skill_data[1] = ceili(_cooldown_timer)


func initialize(player: Player) -> void:
	if player.skill_data.is_empty():
		player.skill_data = [use_times, use_cooldown]
	_player = player
	_initialize()


@rpc("authority", "call_local", "reliable", 2)
func use() -> void:
	_player.skill_data[0] -= 1
	_player.skill_data[1] = use_cooldown
	_use()


func can_use() -> bool:
	return _player.skill_data[0] > 0 and _player.skill_data[1] <= 0 and not _player.is_disarmed()


func _initialize() -> void:
	pass


func _use() -> void:
	pass
