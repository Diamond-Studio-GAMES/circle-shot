class_name MapConfig
extends Resource

@export var map_name := "Карта"
@export_multiline var map_description := "Описание"
@export_file("*.tscn") var map_path: String
@export_file("*.png") var image_path: String
