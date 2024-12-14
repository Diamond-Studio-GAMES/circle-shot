class_name ShapeDetector
extends ShapeCast2D
## Детектор в виде [ShapeCast2D] для [Attack].

## Интервал между нанесениями урона сущностям в этой области.
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
			if not entity.name in _exceptions and _attack.can_deal_damage(entity):
				if multiplayer.is_server():
					_attack.deal_damage(entity)
				_exceptions[entity.name] = damage_interval
	
	for exception: StringName in _exceptions.keys():
		_exceptions[exception] -= delta
		if _exceptions[exception] <= 0.0:
			_exceptions.erase(exception)
