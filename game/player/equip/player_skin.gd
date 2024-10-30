class_name PlayerSkin
extends Sprite2D


@export var custom_hurt_vfx_scene: PackedScene
@export var custom_death_vfx_scene: PackedScene
@export var custom_heal_vfx_scene: PackedScene
var player: Player
var data: SkinData
var _cached_default_hurt_vfx_scene: PackedScene
var _cached_default_heal_vfx_scene: PackedScene
var _cached_default_death_vfx_scene: PackedScene


func _ready() -> void:
	if custom_hurt_vfx_scene:
		_cached_default_hurt_vfx_scene = player.hurt_vfx_scene
		player.hurt_vfx_scene = custom_hurt_vfx_scene
	if custom_heal_vfx_scene:
		_cached_default_heal_vfx_scene = player.heal_vfx_scene
		player.heal_vfx_scene = custom_heal_vfx_scene
	if custom_death_vfx_scene:
		_cached_default_death_vfx_scene = player.death_vfx_scene
		player.death_vfx_scene = custom_death_vfx_scene


func _exit_tree() -> void:
	if _cached_default_hurt_vfx_scene:
		player.hurt_vfx_scene = _cached_default_hurt_vfx_scene
	if _cached_default_heal_vfx_scene:
		player.heal_vfx_scene = _cached_default_heal_vfx_scene
	if _cached_default_death_vfx_scene:
		player.death_vfx_scene = _cached_default_death_vfx_scene
