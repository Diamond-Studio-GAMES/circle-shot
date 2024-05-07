extends Node


const FILE_NAME := "user://save.cfg"
const DEFAULT_SECTION := "save"
var HEADLESS := false
var items_db: ItemsDB = load("uid://pwq1e7l2ckos")
var save_file: ConfigFile


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("dedicated_server"):
		print("Detected headless platform")
		HEADLESS = true
	
	save_file = ConfigFile.new()
	save_file.load(FILE_NAME)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_PREDELETE, \
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST, \
		NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save_file.save(FILE_NAME)


#region Функции задавания и получения значений
func get_variant(id: String, default_value: Variant) -> Variant:
	return save_file.get_value(DEFAULT_SECTION, id, default_value)


func set_variant(id: String, value: Variant) -> void:
	save_file.set_value(DEFAULT_SECTION, id, value)


func get_int(id: String, default_value := 0) -> int:
	var value: int = save_file.get_value(DEFAULT_SECTION, id, default_value)
	return value


func set_int(id: String, value: int) -> void:
	save_file.set_value(DEFAULT_SECTION, id, value)


func get_float(id: String, default_value := 0.0) -> float:
	var value: float = save_file.get_value(DEFAULT_SECTION, id, default_value)
	return value


func set_float(id: String, value: float) -> void:
	save_file.set_value(DEFAULT_SECTION, id, value)


func get_bool(id: String, default_value := false) -> bool:
	var value: bool = save_file.get_value(DEFAULT_SECTION, id, default_value)
	return value


func set_bool(id: String, value: bool) -> void:
	save_file.set_value(DEFAULT_SECTION, id, value)


func get_string(id: String, default_value := "") -> String:
	var value: String = save_file.get_value(DEFAULT_SECTION, id, default_value)
	return value


func set_string(id: String, value: String) -> void:
	save_file.set_value(DEFAULT_SECTION, id, value)
#endregion
