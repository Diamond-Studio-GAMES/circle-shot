class_name Main
extends Node

## Главный класс игры.
##
## Отвечает за переключение между сценами, загрузку игры и прочее.

## Внутренний сигнал, используемый при загрузке.
signal loading_stage_finished(success: bool)

var _menu: Menu
var _game: Game
var _other_screens: Array[Node] = []
@onready var _load_status_label: Label = $LoadingScreen/StatusLabel
@onready var _load_progress_bar: ProgressBar = $LoadingScreen/ProgressBar


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("dedicated_server"):
		print("Detected headless platform")
		Globals.headless = true
	if OS.has_feature("pc"):
		get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	Globals.main = self


## Открывает меню. Закрывает все остальное.
func open_menu() -> void:
	if is_instance_valid(_menu):
		push_warning("Menu is already opened!")
		return
	_clear_screens()
	
	var menu_scene: PackedScene = load("uid://4wb77emq8t5p") # res://menu/main/menu.tscn
	var menu: Menu = menu_scene.instantiate()
	add_child(menu)
	_menu = menu
	print_verbose("Opened menu.")


func open_local_game() -> void:
	if is_instance_valid(_game):
		push_warning("Game is already opened!")
		return
	_clear_screens()
	
	var game_scene: PackedScene = load("uid://scqgxynxowrb") # res://game/core/game.tscn
	var game: Game = game_scene.instantiate()
	add_child(game)
	game.init_connect_local_menu()
	_game = game
	print_verbose("Opened game with local menu.")


## Выдаёт критическую ошибку, которая останавливает всю игру. Использовать только в безвыходных
## ситуациях. Если [param info] не пустое, отображает дополнительную информацию.
func show_critical_error(info := "", log_error := "") -> void:
	get_tree().paused = true
	var dialog := AcceptDialog.new()
	dialog.title = "Критическая ошибка!"
	dialog.dialog_text = "Произошла критическая ошибка. Подробности можно найти в логах. \
			Игра будет завершена при закрытии этого диалога."
	if not info.is_empty():
		dialog.dialog_text += "\nИнформация: %s." % info
	if not log_error.is_empty():
		push_error(log_error)
	dialog.canceled.connect(get_tree().quit)
	dialog.confirmed.connect(get_tree().quit)
	dialog.transient = true
	dialog.exclusive = true
	dialog.process_mode = PROCESS_MODE_ALWAYS
	add_child(dialog)
	dialog.popup_centered()


func _start_load() -> void:
	$SplashScreen.queue_free()
	($LoadingScreen/AnimationPlayer as AnimationPlayer).play(&"Begin")
	
	_load_check_server()
	var success: bool = await loading_stage_finished
	if success:
		# Загрузка данных
		# Синхронизация версии
		pass
	
	# Загрузка треков
	# Загрузка в память
	_load_open_menu()
	await loading_stage_finished
	$LoadingScreen.queue_free()


func _load_check_server() -> void:
	print_verbose("Checking connection to server...")
	_load_status_label.text = "Проверка соединения с сервером..."
	_load_progress_bar.value = 0
	await get_tree().process_frame
	
	var http := HTTPRequest.new()
	http.request_completed.connect(_on_check_http_request_completed.bind(http))
	add_child(http)
	
	var err: Error = http.request("https://diamond-studio-games.github.io/README.md")
	if err != OK:
		push_warning("Can't connect to server! Error: %s" % error_string(err))
		loading_stage_finished.emit(false)
		http.queue_free()


func _on_check_http_request_completed(result: HTTPRequest.Result, response_code: HTTPClient.ResponseCode,
		_headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Connect to server: result is not Success! Result: %d" % result)
		loading_stage_finished.emit(false)
		return
	if response_code != HTTPClient.RESPONSE_OK:
		push_warning("Connect to server: response code is not 200! Response code: %d" % response_code)
		loading_stage_finished.emit(false)
		return
	loading_stage_finished.emit(true)
	print_verbose("Connection success.")


func _load_open_menu() -> void:
	print_verbose("Opening menu...")
	_load_status_label.text = "Загрузка меню..."
	_load_progress_bar.value = 100
	await get_tree().process_frame
	
	open_menu()
	# Чтобы меню было под загр. экраном
	move_child($LoadingScreen, 1)
	($LoadingScreen/AnimationPlayer as AnimationPlayer).play(&"End")
	await ($LoadingScreen/AnimationPlayer as AnimationPlayer).animation_finished
	loading_stage_finished.emit(true)


func _clear_screens() -> void:
	if is_instance_valid(_menu):
		_menu.queue_free()
	if is_instance_valid(_game):
		_game.queue_free()
	for i: Node in _other_screens:
		i.queue_free()
	_other_screens.clear()
	print_verbose("Screens cleared.")
