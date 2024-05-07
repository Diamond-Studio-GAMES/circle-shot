class_name Weapon
extends Node2D


enum Type {
	LIGHT = 0,
	HEAVY = 1,
	SUPPORT = 2,
	MELEE = 3,
}
@export var ammo_per_load := 10
@export var ammo_total := 150
var ammo := 10
var player: Player
@warning_ignore("unused_private_class_variable") # Для дочерних классов
@onready var _projectiles_parent: Node2D = get_tree().get_first_node_in_group("ProjectilesParent")


func _ready() -> void:
	ammo = ammo_per_load


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
	_unmake_current()


func get_ammo_text() -> String:
	if ammo + ammo_total <= 0:
		return "Нет патронов"
	return "%d/%d" % [ammo, ammo_total]


func _shoot() -> void:
	pass


func _make_current() -> void:
	pass


func _unmake_current() -> void:
	pass


func _can_use_weapon() -> bool:
	return player.can_use_weapon and player.can_control
