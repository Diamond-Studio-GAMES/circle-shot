@tool
class_name GameConfig
extends Resource


@export_group("Config")
@export var game_name := "Королевская битва"
@export_multiline var game_description := "Побеждает последний выживший!"
@export_file("*.tscn") var game_path: String
@export_file("*.png") var image_path: String
@export var maps_count := 0:
	set(value):
		var old_size := maps_count
		maps_count = value
		maps.resize(value)
		if old_size < value:
			for i: int in range(old_size, value):
				maps[i]["name"] = "Карта"
				maps[i]["description"] = "Описание"
				maps[i]["path"] = "res://core/game.tscn"
				maps[i]["image_path"] = "res://icon.png"
		notify_property_list_changed()
@export_group("", "")
@export_storage var maps: Array[Dictionary]


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	for i: int in range(maps_count):
		properties.append({
			"name": "maps/%d/name" % (i + 1),
			"type": TYPE_STRING,
		})
		properties.append({
			"name": "maps/%d/description" % (i + 1),
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT,
		})
		properties.append({
			"name": "maps/%d/path" % (i + 1),
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn",
		})
		properties.append({
			"name": "maps/%d/image_path" % (i + 1),
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.tscn",
		})
	return properties


func _get(property: StringName) -> Variant:
	if not property.begins_with("maps/"):
		return
	var splits := property.split("/")
	var idx := int(splits[1]) - 1
	return maps[idx][splits[2]]


func _set(property: StringName, value: Variant) -> bool:
	if not property.begins_with("maps/"):
		return false
	var splits := property.split("/")
	var idx := int(splits[1]) - 1
	maps[idx][splits[2]] = value
	return true
