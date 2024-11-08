class_name AreaDetector
extends Area2D


@export var damage_interval := 1.0
var _entities: Array[Entity]
var _exceptions: Dictionary[StringName, float]
@onready var _attack: Attack = get_parent()


func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	for i: Entity in _entities:
		if not i.name in _exceptions:
			_attack.deal_damage(i)
			_exceptions[i.name] = damage_interval
	
	for i: StringName in _exceptions.keys():
		_exceptions[i] -= delta
		if _exceptions[i] <= 0.0:
			_exceptions.erase(i)


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
