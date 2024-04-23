class_name Weapon
extends Node2D

@export var per_load_ammo := 10
@export var total_ammo := 150
var ammo := 10

var _player: Player


func _ready() -> void:
	hide()
	process_mode = PROCESS_MODE_DISABLED


@rpc("call_local", "reliable", "authority", 2)
func shoot() -> void:
	_shoot()


@rpc("call_local", "reliable", "authority", 2)
func make_current() -> void:
	show()
	process_mode = PROCESS_MODE_INHERIT
	_make_current()


@rpc("call_local", "reliable", "authority", 2)
func unmake_current() -> void:
	hide()
	process_mode = PROCESS_MODE_DISABLED


func get_ammo_text() -> String:
	return "%d/%d" % [ammo, total_ammo]


func _shoot() -> void:
	pass


func _make_current() -> void:
	pass
