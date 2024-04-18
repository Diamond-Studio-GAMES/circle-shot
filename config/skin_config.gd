class_name SkinConfig
extends Resource

@export var skin_name := "Классический"
@export var skin_description := "Это база"
@export var rarity := ItemsDB.Rarity.COMMON
@export_file("*.tscn") var skin_path: String
@export_file("*.png") var image_path: String
