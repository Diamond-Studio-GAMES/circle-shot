class_name Shooter
extends Node

var _lobby := preload("res://menu/lobby.tscn")
const PORT = 14889
const MAX_CLIENTS = 10


func _ready() -> void:
	_create_lobby()


func create_game():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer


func join_game(ip: String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer


func _create_lobby():
	var lobby := _lobby.instantiate() as Lobby
	lobby.game_created.connect(create_game)
	lobby.game_joined.connect(join_game)
	add_child(lobby)
