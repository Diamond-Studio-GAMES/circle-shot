class_name AreaDetector
extends Area2D

## Детектор в виде [Area2D] для [Attack].

## Интервал между нанесениями урона сущностям в этой области.
@export var damage_interval := 1.0
var _entities: Array[Entity]
var _exceptions: Dictionary[StringName, float]
@onready var _attack: Attack = get_parent()


func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	for entity: Entity in _entities:
		if not entity.name in _exceptions:
			var success: bool = _attack.deal_damage(entity)
			if success:
				_exceptions[entity.name] = damage_interval
	
	for exception: StringName in _exceptions.keys():
		_exceptions[exception] -= delta
		if _exceptions[exception] <= 0.0:
			_exceptions.erase(exception)


func _on_body_entered(body: Node2D) -> void:
	var entity := body as Entity
	if not entity:
		return
	_entities.append(entity)


func _on_body_exited(body: Node2D) -> void:
	var entity := body as Entity
	if not entity:
		return
	_entities.erase(entity)
