class_name Attack
extends Area2D

@export var damage: int = 10
@export var who := -1
@export var team := -1

func _ready() -> void:
	monitorable = false
	if not multiplayer.is_server():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(_body: Node2D) -> void:
	pass


func _on_body_exited(_body: Node2D) -> void:
	pass
