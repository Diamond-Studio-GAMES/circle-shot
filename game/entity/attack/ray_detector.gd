class_name RayDetector
extends RayCast2D


signal hit(where: Vector2)
@export var damage_interval := 0.3
var _exceptions: Dictionary[StringName, float]
@onready var _attack: Attack = get_parent()


func _physics_process(delta: float) -> void:
	if is_colliding():
		var entity := get_collider() as Entity
		if entity:
			if entity.team == _attack.team:
				add_exception(entity)
				force_raycast_update()
				_physics_process(delta)
				return
			if not entity.name in _exceptions:
				if multiplayer.is_server():
					_attack.deal_damage(entity)
				_exceptions[entity.name] = damage_interval
				hit.emit(get_collision_point())
		else:
			hit.emit(get_collision_point())
	
	for i: StringName in _exceptions.keys():
		_exceptions[i] -= delta
		if _exceptions[i] <= 0.0:
			_exceptions.erase(i)
