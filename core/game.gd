class_name Game
extends Node


@onready var _players: Node = $Players


func _physics_process(_delta: float) -> void:
	for i: Player in _players.get_children():
		pass

