extends "res://game/weapons/melee/common/melee.gd"


func _initialize() -> void:
	($Base/Light as Node2D).self_modulate = Entity.TEAM_COLORS[_player.team]
	($AttackPolygon as Polygon2D).color = Entity.TEAM_COLORS[_player.team]
