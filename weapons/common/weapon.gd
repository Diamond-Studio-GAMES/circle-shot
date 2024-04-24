class_name Weapon
extends Node2D

enum Type {
	LIGHT = 0,
	HEAVY = 1,
	SUPPORT = 2,
	MELEE = 3,
}
@export var per_load_ammo := 10
@export var total_ammo := 150
var ammo := 10
var player: Player
@warning_ignore("unused_private_class_variable") # For child classes
@onready var _projectiles_parent: Node2D = get_tree().get_first_node_in_group("ProjectilesParent")


func _ready() -> void:
	ammo = per_load_ammo


@rpc("call_local", "reliable", "authority", 2)
func shoot() -> void:
	_shoot()
	player.ammo_text_updated.emit(get_ammo_text())


func make_current() -> void:
	show()
	process_mode = PROCESS_MODE_INHERIT
	_make_current()


func unmake_current() -> void:
	hide()
	process_mode = PROCESS_MODE_DISABLED


func get_ammo_text() -> String:
	return "%d/%d" % [ammo, total_ammo]


func _shoot() -> void:
	pass


func _make_current() -> void:
	pass
