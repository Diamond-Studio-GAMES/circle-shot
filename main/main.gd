class_name Main
extends Node

## Главный класс игры.
##
## Отвечает за переключение между сценами, загрузку игры и прочее.

## Внутренний сигнал, используемый при загрузке.
signal loading_stage_finished(success: bool)

## Список путей к сценам для загрузки в память при запуске игры. Ускоряет последующую загрузку
## этих сцен.
@export_file("Resource") var resources_to_preload_paths: Array[String]
var game: Game
var _menu: Menu
var _other_screens: Array[Node]
var _preloaded_resources: Array[Resource]
@onready var _load_status_label: Label = $LoadingScreen/StatusLabel
@onready var _load_progress_bar: ProgressBar = $LoadingScreen/ProgressBar


## Открывает меню. Закрывает все остальное.
func open_menu() -> void:
	if is_instance_valid(_menu):
		push_error("Menu is already opened!")
		return
	_clear_screens()
	
	var menu_scene: PackedScene = load("uid://4wb77emq8t5p")
	var menu: Menu = menu_scene.instantiate()
	add_child(menu)
	_menu = menu
	print_verbose("Opened menu.")


## Открывает настройки.
func open_settings() -> void:
	var settings_scene: PackedScene = load("uid://c2leb2h0qjtmo")
	var settings: Control = settings_scene.instantiate()
	add_child(settings)
	_other_screens.append(settings)
	print_verbose("Opened settings.")


## Открывает игру с меню локальной игры. Закрывает всё остальное.
func open_local_game() -> void:
	if is_instance_valid(game):
		push_error("Game is already opened!")
		return
	_clear_screens()
	
	var game_scene: PackedScene = load("uid://scqgxynxowrb")
	var loaded_game: Game = game_scene.instantiate()
	add_child(loaded_game)
	loaded_game.init_connect_local()
	game = loaded_game
	print_verbose("Opened game with local menu.")


## Удаляет экран, указанный в [param screen].
func close_screen(screen: Control) -> void:
	_other_screens.erase(screen)
	screen.queue_free()


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


## Устанавливает настройки по умолчанию, если их ещё нет.
func setup_settings() -> void:
	var override_file := ConfigFile.new()
	override_file.load("user://engine_settings.cfg")
	var preffered_renderer: String = ProjectSettings.get_setting_with_override(
			&"rendering/renderer/rendering_method"
	)
	var shader_cache: bool = ProjectSettings.get_setting_with_override(
			&"rendering/shader_compiler/shader_cache/enabled"
	)
	override_file.set_value(
			"rendering", "shader_compiler/shader_cache/enabled", shader_cache
	)
	override_file.set_value(
			"rendering", "shader_compiler/shader_cache/enabled.mobile", shader_cache
	)
	override_file.set_value(
			"rendering", "rendering_device/pipeline_cache/enable", shader_cache
	)
	override_file.set_value(
			"rendering", "rendering_device/pipeline_cache/enable.mobile", shader_cache
	)
	override_file.set_value(
			"rendering", "renderer/rendering_method", preffered_renderer
	)
	override_file.set_value(
			"rendering", "renderer/rendering_method.mobile", preffered_renderer
	)
	override_file.save("user://engine_settings.cfg")
	
	Globals.set_setting_bool(
			"hit_markers",
			Globals.get_setting_bool("hit_markers", true)
	)
	Globals.set_setting_bool(
			"minimap",
			Globals.get_setting_bool("minimap", true)
	)
	Globals.set_setting_bool(
			"debug_data",
			Globals.get_setting_bool("debug_data", false)
	)
	Globals.set_setting_float(
			"master_volume",
			Globals.get_setting_float("master_volume", 1.0)
	)
	Globals.set_setting_float(
			"music_volume",
			Globals.get_setting_float("music_volume", 1.0)
	)
	Globals.set_setting_float(
			"sfx_volume",
			Globals.get_setting_float("sfx_volume", 1.0)
	)
	Globals.set_setting_bool(
			"fullscreen",
			Globals.get_setting_bool("fullscreen", OS.has_feature("mobile"))
	)
	Globals.set_setting_bool(
			"preload",
			Globals.get_setting_bool("preload", true)
	)


## Устанавливает настройки управления по умолчанию, если их ещё нет.
func setup_controls_settings() -> void:
	Globals.save_file.set_value(Globals.CONTROLS_SAVE_FILE_SECTION, "xD", "xD")


## Применяет общие настройки.
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(&"Master"), linear_to_db(Globals.get_float("master_volume"))
	)
	AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(&"Music"), linear_to_db(Globals.get_float("music_volume"))
	)
	AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(&"SFX"), linear_to_db(Globals.get_float("sfx_volume"))
	)
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN \
			if Globals.get_setting_bool("fullscreen") else Window.MODE_WINDOWED


func _clear_screens() -> void:
	if is_instance_valid(_menu):
		_menu.queue_free()
	if is_instance_valid(game):
		game.queue_free()
	for i: Node in _other_screens:
		i.queue_free()
	_other_screens.clear()
	print_verbose("Screens cleared.")


func _start_load() -> void:
	$SplashScreen.queue_free()
	($LoadingScreen/AnimationPlayer as AnimationPlayer).play(&"Begin")
	_loading_init()
	await loading_stage_finished
	
	_loading_check_server()
	var success: bool = await loading_stage_finished
	if success:
		# Загрузка данных
		# Синхронизация версии
		pass
	
	# Загрузка треков
	
	_loading_preload_resources()
	await loading_stage_finished
	
	_loading_open_menu()
	await loading_stage_finished
	$LoadingScreen.queue_free()


func _loading_init() -> void:
	print_verbose("Initializing...")
	_load_status_label.text = "Инициализация..."
	_load_progress_bar.value = 0
	await get_tree().process_frame
	
	Globals.initialize(self)
	if DisplayServer.get_name() == "headless" or OS.has_feature("dedicated_server"):
		print("Detected headless platform")
		Globals.headless = true
	if OS.has_feature("pc"):
		get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	multiplayer.multiplayer_peer = null # Чтобы убрать OfflineMultiplayerPeer
	get_viewport().set_canvas_cull_mask_bit(1, false)
	setup_settings()
	setup_controls_settings()
	apply_settings()
	
	await get_tree().process_frame
	print_verbose("Done initializing.")
	loading_stage_finished.emit(true)


func _loading_check_server() -> void:
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
	print_verbose("Connection success.")
	loading_stage_finished.emit(true)


func _loading_preload_resources() -> void:
	if not Globals.get_setting_bool("preload"):
		print_verbose("Not preloading resources: disabled.")
		loading_stage_finished.emit(true)
		return
	
	print_verbose("Preloading resources...")
	_load_status_label.text = "Загрузка ресурсов в память..."
	_load_progress_bar.value = 0
	await get_tree().process_frame
	
	var counter: int = 1
	var to_preload: Array[String]
	to_preload.append_array(resources_to_preload_paths)
	var to_preload_count: int = to_preload.size()
	
	var last_ticks: int = Time.get_ticks_msec()
	for i: String in to_preload:
		var resource: Resource = load(i)
		_preloaded_resources.append(resource)
		_load_progress_bar.value = 100.0 * counter / to_preload_count
		counter += 1
		print_verbose("Preloaded resource: %s." % i)
		if Time.get_ticks_msec() - last_ticks > 16:
			await get_tree().process_frame
			last_ticks = Time.get_ticks_msec()
	
	print_verbose("Done preloading resources.")
	loading_stage_finished.emit(true)


func _loading_open_menu() -> void:
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
