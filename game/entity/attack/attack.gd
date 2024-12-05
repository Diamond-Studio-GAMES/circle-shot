class_name Attack
extends Node2D

@export var damage: int
var damage_multiplier := 1.0
var who: int = -1
var team: int = -1

func deal_damage(entity: Entity, amount: int = damage) -> bool:
	if not can_deal_damage(entity):
		return false
	entity.damage(roundi(amount * damage_multiplier), who)
	_deal_damage(entity)
	return true


func can_deal_damage(entity: Entity) -> bool:
	return entity.team != team and _can_deal_damage(entity)


func _deal_damage(_entity: Entity) -> void:
	pass


func _can_deal_damage(_entity: Entity) -> bool:
	return true
