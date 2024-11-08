class_name ShapeDetector
extends ShapeCast2D

@export var damage_interval := 0.3
var _exceptions: Dictionary[StringName, float]
@onready var _attack: Attack = get_parent()

func _physics_process(delta: float) -> void:
	if is_colliding():
		var entity := get_collider(0) as Entity
		if entity:
			if entity.team == _attack.team:
				add_exception(entity)
				force_shapecast_update()
				_physics_process(delta)
				return
			if not entity.name in _exceptions:
				if multiplayer.is_server():
					_attack.deal_damage(entity)
				_exceptions[entity.name] = damage_interval
	
	for i: StringName in _exceptions.keys():
		_exceptions[i] -= delta
		if _exceptions[i] <= 0.0:
			_exceptions.erase(i)
