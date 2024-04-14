class_name GameConfig
extends Resource

@export var game_name := "Королевская битва"
@export_multiline var game_description := "Побеждает последний выживший!"
@export_file("*.tscn") var game_path: String
@export_file("*.png") var image_path: String
@export var maps: Array[MapConfig]
