class_name Globals
extends Node

const items_db: ItemsDB = preload("uid://pwq1e7l2ckos")
var HEADLESS := false

# Path of user settings and items
const file_name = "user://save.cfg"
var save_file: ConfigFile

func _ready() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("server"):
		print("Detected headless platform")
		HEADLESS = true
	
	save_file = ConfigFile.new()
	save_file.load(file_name)
	

# Functions for save file operations 
func get_value(name: String, default_value: Variant = 0) -> Variant:
	return save_file.get_value("save", name, default_value)

func set_value(name: String, value: Variant) -> void:
	save_file.set_value("save", name, value)
