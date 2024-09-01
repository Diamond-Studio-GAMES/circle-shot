extends Node

## Глобальный класс игры.
##
## Этот класс содержит в себе то, что используется по всей игре. Также отвечает за сохранения.

## Путь к файлу сохранения.
const SAVE_FILE_PATH := "user://save.cfg"
## Секция файла сохранения.
const SAVE_FILE_SECTION := "save"
## Ссылка на [Main]. Сокращение от [code]get_tree().current_scene as Main[/code].
var main: Main
## Версия игры. Извлекается из [ProjectSettings].
var version: String = ProjectSettings.get_setting("application/config/version")
## Находится ли игра в "безголовом режиме". Если да, то сервер создаётся без игрока.
## Если этот режим будет включён на запуске, то игра автоматически создаст сервер.
var headless := false
## База данных всех предметов. Смотри [ItemsDB].
var items_db: ItemsDB = load("uid://pwq1e7l2ckos")
## Файл сохранения. Не модифицируйте его напрямую, используете методы [code]get_*/set_*[/code].
var save_file: ConfigFile


func _ready() -> void:
	save_file = ConfigFile.new()
	save_file.load(SAVE_FILE_PATH)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_PREDELETE, \
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST, \
		NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save_file.save(SAVE_FILE_PATH)


#region Функции задавания и получения значений
## Получает значение типа [Variant] по [param id]. Если его нет, вернёт [param default_value].
func get_variant(id: String, default_value: Variant) -> Variant:
	return save_file.get_value(SAVE_FILE_SECTION, id, default_value)


## Задаёт значение типа [Variant] под [param id].
func set_variant(id: String, value: Variant) -> void:
	save_file.set_value(SAVE_FILE_SECTION, id, value)


## Получает значение типа [int] по [param id]. Если его нет, вернёт [param default_value].
func get_int(id: String, default_value := 0) -> int:
	var value: int = save_file.get_value(SAVE_FILE_SECTION, id, default_value)
	return value


## Задаёт значение типа [int] под [param id].
func set_int(id: String, value: int) -> void:
	save_file.set_value(SAVE_FILE_SECTION, id, value)


## Получает значение типа [float] по [param id]. Если его нет, вернёт [param default_value].
func get_float(id: String, default_value := 0.0) -> float:
	var value: float = save_file.get_value(SAVE_FILE_SECTION, id, default_value)
	return value


## Задаёт значение типа [float] под [param id].
func set_float(id: String, value: float) -> void:
	save_file.set_value(SAVE_FILE_SECTION, id, value)


## Получает значение типа [bool] по [param id]. Если его нет, вернёт [param default_value].
func get_bool(id: String, default_value := false) -> bool:
	var value: bool = save_file.get_value(SAVE_FILE_SECTION, id, default_value)
	return value


## Задаёт значение типа [bool] под [param id].
func set_bool(id: String, value: bool) -> void:
	save_file.set_value(SAVE_FILE_SECTION, id, value)


## Получает значение типа [String] по [param id]. Если его нет, вернёт [param default_value].
func get_string(id: String, default_value := "") -> String:
	var value: String = save_file.get_value(SAVE_FILE_SECTION, id, default_value)
	return value


## Задаёт значение типа [String] под [param id].
func set_string(id: String, value: String) -> void:
	save_file.set_value(SAVE_FILE_SECTION, id, value)
#endregion
