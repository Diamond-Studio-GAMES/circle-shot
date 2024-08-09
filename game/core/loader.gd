class_name Loader
extends CanvasLayer

signal loaded
signal load_failed
signal loaded_part(success: bool)
var _loading := false
var _loaded_part := false
var _loaded_part_node: Node
var _loading_path: String
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _bar: ProgressBar = $Background/ProgressBar
@onready var _status_text: Label = $Background/ProgressBar/Label


func _process(_delta: float) -> void:
	if _loading:
		var progress: Array[float] = []
		var status := ResourceLoader.load_threaded_get_status(_loading_path, progress)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				loaded_part.emit(true)
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				_bar.value = roundf(progress[0] * 50) + 50 * int(_loaded_part)
			_:
				loaded_part.emit(false)


func load_event(event: int, map: int) -> void:
	_anim.play("StartLoad")
	_status_text.text = "Загрузка игры..."
	_loading_path = Globals.items_db.events[event].scene_path
	var err: int = ResourceLoader.load_threaded_request(_loading_path)
	if err:
		_fail_load()
		return
	_loading = true
	_loaded_part = false
	var success: bool = await loaded_part
	if not success:
		_fail_load()
		return
	var event_scene: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
	var event_node: Event = event_scene.instantiate()
	_loaded_part = true
	_bar.value = 50
	_status_text.text = "Загрузка карты..."
	_loading_path = Globals.items_db.events[event].maps[map].scene_path
	err = ResourceLoader.load_threaded_request(_loading_path)
	if err:
		_fail_load()
		return
	success = await _loaded_part
	if not success:
		_fail_load()
		return
	var map_scene: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
	var map_node: Node2D = map_scene.instantiate()
	event_node.add_child(map_node)
	_loading = false
	_bar.value = 100
	_status_text.text = "Ожидание других игроков..."
	loaded.emit()


func finish_load() -> void:
	_status_text.text = "Готово!"
	_anim.play("EndLoad")


func _fail_load() -> void:
	load_failed.emit()
	var game_node: Game = get_node_or_null("../Game")
	if game_node:
		game_node.queue_free()
	_loading = false
	_anim.play("EndLoad")
	_status_text.text = "Ошибка загрузки!"


func _on_connection_closed() -> void:
	if _loading:
		_fail_load()
