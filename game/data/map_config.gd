class_name MapConfig
extends Resource

@export var map_name: String
@export_multiline var map_description: String
@export_file("*.tscn") var map_path: String
@export_file("*.png") var image_path: String
