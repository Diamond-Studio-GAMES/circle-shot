class_name Attack
extends Node2D

@export var damage: int
var who: int = -1
var team: int = -1

func deal_damage(entity: Entity, amount: int = damage) -> bool:
	if entity.team == team:
		return false
	entity.damage(amount, who)
	_deal_damage(entity)
	return true


func _deal_damage(_entity: Entity) -> void:
	pass
