extends Area2D

@export var damage_interval := 1.0
var _entities := {}
@onready var _attack: Attack = get_parent()

func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	for i: Entity in _entities:
		_entities[i] -= delta
		if _entities[i] <= 0:
			_attack.deal_damage(i)
			_entities[i] = damage_interval


func _on_body_entered(body: Node2D) -> void:
	var entity := body as Entity
	if not entity:
		return
	_entities[entity] = 0.01


func _on_body_exited(body: Node2D) -> void:
	var entity := body as Entity
	if not entity:
		return
	_entities.erase(entity)
