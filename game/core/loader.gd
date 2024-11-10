class_name Loader
extends CanvasLayer

## Класс, который занимается загрузкой.
##
## В комбинации с [Game], загружает события и прочее.

## Внутренний сигнал, издаётся при завершении части общей загрузки.
signal loaded_part(success: bool)
var _loaded_part := false
var _loading_path: String
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _bar: ProgressBar = $Screen/ProgressBar
@onready var _status_text: Label = $Screen/ProgressBar/Label


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	var progress: Array[float]
	var status: ResourceLoader.ThreadLoadStatus = \
			ResourceLoader.load_threaded_get_status(_loading_path, progress)
	print_verbose("Status for loading %s: progress - %f, status - %d." % [
		_loading_path,
		progress[0],
		status,
	])
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			loaded_part.emit(true)
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_bar.value = roundf(progress[0] * 50) + 50 * int(_loaded_part)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loaded_part.emit(false)


## Загружает события и карту по [param event_id] и [param map_id] соответственно. Возвращает [Event],
## если загрузка прошла удачно, иначе возвращает [code]null[/code].[br]
## [b]Внимание[/b]: этот метод - [b]корутина[/b], так что вам необходимо подождать его с помощью
## [code]await[/code].
func load_event(event_id: int, map_id: int) -> Event:
	_anim.play(&"StartLoad")
	_status_text.text = "Загрузка события..."
	
	_loading_path = Globals.items_db.events[event_id].scene_path
	print_verbose("Requesting load for event path %s." % _loading_path)
	var err: Error = ResourceLoader.load_threaded_request(_loading_path)
	if err != OK:
		push_error("Load request for event %s failed with error: %s." % [
			_loading_path,
			error_string(err)
		])
		_fail_load()
		return null
	set_process(true)
	_loaded_part = false
	
	var success: bool = await loaded_part
	if not success:
		push_error("Loading of event %s failed!" % _loading_path)
		_fail_load()
		return null
	var event_scene: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
	if not is_instance_valid(event_scene):
		# TODO: удалить эту шарманку.
		push_error("Loading of event %s failed!" % _loading_path)
		_fail_load()
		return null
	print_verbose("Done loading event %s." % _loading_path)
	var event: Event = event_scene.instantiate()
	_loaded_part = true
	
	_bar.value = 50
	_status_text.text = "Загрузка карты..."
	
	_loading_path = Globals.items_db.events[event_id].maps[map_id].scene_path
	print_verbose("Requesting load for map path %s." % _loading_path)
	err = ResourceLoader.load_threaded_request(_loading_path)
	if err != OK:
		push_error("Load request for map %s failed with error: %s." % [
			_loading_path,
			error_string(err)
		])
		event.free()
		_fail_load()
		return null
	
	success = await loaded_part
	if not success:
		push_error("Loading of map %s failed!" % _loading_path)
		event.free()
		_fail_load()
		return null
	var map_scene: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
	if not is_instance_valid(map_scene):
		# TODO: удалить эту шарманку.
		push_error("Loading of map %s failed!" % _loading_path)
		event.free()
		_fail_load()
		return null
	print_verbose("Done loading map %s." % _loading_path)
	var map: Node = map_scene.instantiate()
	event.add_child(map)
	
	set_process(false)
	_bar.value = 100
	_status_text.text = "Ожидание других игроков..."
	print_verbose("Done loading event.")
	return event


## Завершает загрузку, а именно анимацию.
func finish_load() -> void:
	_status_text.text = "Готово!"
	_anim.play(&"EndLoad")
	print_verbose("Load finished.")


func _fail_load() -> void:
	set_process(false)
	_anim.play(&"EndLoad")
	_status_text.text = "Ошибка загрузки!"
	print_verbose("Load failed.")


func _on_game_closed() -> void:
	if is_processing():
		print_verbose("Game closed, aborting load.")
		loaded_part.emit(false)
