class_name SkinConfig
extends Resource

@export var skin_name: String
@export var skin_description: String
@export var rarity := ItemsDB.Rarity.COMMON
@export_file("*.tscn") var skin_path: String
@export_file("*.png") var image_path: String
