class_name SkinConfig
extends Resource

enum Rarity {
	COMMON = 0,
	RARE = 1,
	EPIC = 2,
	LEGENDARY = 3,
	SECRET = 4,
}

@export var skin_name := "Классический"
@export var skin_description := "Это база"
@export var rarity := Rarity.COMMON
@export_file("*.tscn") var skin_path: String
@export_file("*.png") var image_path: String
