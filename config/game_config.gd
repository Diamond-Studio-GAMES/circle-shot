class_name GameConfig
extends Resource

@export var game_name: String
@export_multiline var game_description: String
@export_file("*.tscn") var game_path: String
@export_file("*.png") var image_path: String
@export var maps: Array[MapConfig]
