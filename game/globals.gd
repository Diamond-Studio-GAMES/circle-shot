class_name Globals
extends Node

const items_db: ItemsDB = preload("uid://pwq1e7l2ckos")
var HEADLESS := false


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("server"):
		print("Detected headless platform")
		HEADLESS = true
