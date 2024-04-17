class_name GameLoader
extends CanvasLayer

signal game_loaded(success: bool)
signal _loaded_part(success: bool)
var _is_loading := false
var _loaded_game := false
var _loading_path: String
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _bar: ProgressBar = $Background/ProgressBar
@onready var _status_text: Label = $Background/ProgressBar/Label


func _process(_delta: float) -> void:
	if _is_loading:
		var progress: Array[int] = [0]
		var status := ResourceLoader.load_threaded_get_status(_loading_path, progress)
		match status:
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_loaded_part.emit(false)
			ResourceLoader.THREAD_LOAD_LOADED:
				_loaded_part.emit(true)
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				_bar.value = progress[0] / 2 + 50 * int(_loaded_game)


func load_game(game: int, map: int) -> void:
	_anim.play("StartLoad")
	_status_text.text = "Загрузка игры..."
	var _loading_path := Global.items_db.games[game].game_path
	ResourceLoader.load_threaded_request(_loading_path)
	_is_loading = true
	_loaded_game = false
	var success: bool = await _loaded_part
	if not success:
		_end_load(false)
		return
	var game_scene: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
	var game_node: Game = game_scene.instantiate()
	get_parent().add_child(game_node, true)


func _end_load(success: bool) -> void:
	game_loaded.emit(success)
	_is_loading = false
	_status_text.text = "Готово!" if success else "Ошибка загрузки!"
	_anim.play("EndLoad")
