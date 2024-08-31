extends RayCast2D

signal hit(where: Vector2)
var _current_collider: Object
@onready var _attack: Attack = get_parent()

func _physics_process(delta: float) -> void:
	if not is_colliding():
		_current_collider = null
		return
	
	if get_collider() == _current_collider:
		return
	
	_current_collider = get_collider()
	var entity := _current_collider as Entity
	if entity:
		if entity.team == _attack.team:
			add_exception(entity)
			force_raycast_update()
			_physics_process(delta)
			return
		if multiplayer.is_server():
			_attack.deal_damage(entity)
	
	hit.emit(get_collision_point())
