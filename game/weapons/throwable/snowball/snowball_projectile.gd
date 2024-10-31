extends "res://game/weapons/guns/common/bullet.gd"

@export var effect_duration: float = 1.0
@export var effect_multiplier: float = 0.5
@export var should_stack := true

func _damage_player(player: Player, amount: int = damage) -> void:
	#super(player, amount)
	player.add_effect.rpc(Effect.SPEED_CHANGE, effect_duration, [effect_multiplier], should_stack)
