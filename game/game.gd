class_name Game
extends Node

@warning_ignore("unused_signal") # Connected dynamically
signal game_ended

@onready var _players: Node = $Players


func start_game(player_data: Dictionary) -> void:
	prints("game started!", multiplayer.get_unique_id())
	print("player data: ", player_data)
