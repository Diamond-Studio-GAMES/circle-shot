class_name Main
extends Node

## Главный класс игры.
##
## Отвечает за переключение между сценами, загрузку игры и прочее.

## Внутренний сигнал, используемый при загрузке.
signal loading_stage_finished(success: bool)
## Перечисление с возможными методами ввода.
enum InputMethod {
	## Клавиатура и мышь.
	KEYBOARD_AND_MOUSE = 0,
	## Касаниями.
	TOUCH = 1,
}
## Перечисление с допустимыми типами событий для действия при использовании
## [enum Main.InputMethod.KEYBOARD_AND_MOUSE].
enum ActionEventType {
	## События типа [InputEventKey].
	KEY = 0,
	## События типа [InputEventMouseButton].
	MOUSE_BUTTON = 1,
}
## Максимальное соотношение ширины к высоте, превысив которое содержимое окна начнёт обрезаться.
const MAX_ASPECT_RATIO := 2.34
## Минимальное соотношение ширины к высоте, пренизив которое содержимое окна начнёт обрезаться.
const MIN_ASPECT_RATIO := 1.5
## Разрешённые расширения файлов для загрузки в качестве пользовательских треков.
const ALLOWED_MUSIC_FILE_EXTENSIONS: Array[String] = [".mp3", ".ogg"]
## Максимальная длина названия файла пользовательского трека. Лишнее обрезается.
const MAX_MUSIC_FILE_NAME_LENGTH: int = 45

## Список путей к сценам для загрузки в память при запуске игры. Ускоряет последующую загрузку
## этих сцен.
@export_file("Resource") var resources_to_preload_paths: Array[String]
## Ссылка на [Game]. Может отсутствовать.
var game: Game
## Ссылка на [Menu]. Может отсутствовать.
var menu: Menu
## Список открытых на данный момент экранов.
var screens: Array[Control]
## Словарь загруженных пользовательских треков в формате "<имя файла> : <ресурс трека>".
var loaded_custom_tracks: Dictionary[String, AudioStream]
var _preloaded_resources: Array[Resource]

## Путь до папки с пользовательскими треками.
@onready var music_path: String = OS.get_system_dir(OS.SYSTEM_DIR_MUSIC).path_join("Circle Shot")
@onready var _default_window_content_width: int = \
		ProjectSettings.get_setting("display/window/size/viewport_width")
@onready var _default_window_content_height: int = \
		ProjectSettings.get_setting("display/window/size/viewport_height")
@onready var _load_status_label: Label = $LoadingScreen/StatusLabel
@onready var _load_progress_bar: ProgressBar = $LoadingScreen/ProgressBar


func _input(event: InputEvent) -> void:
	if OS.has_feature("pc") and event.is_action(&"fullscreen") \
			and event.is_pressed() and Globals.save_file:
		Globals.set_setting_bool("fullscreen", not Globals.get_setting_bool("fullscreen"))
		apply_settings()


## Открывает меню. Закрывает все остальное.
func open_menu() -> void:
	if is_instance_valid(menu):
		push_error("Menu is already opened!")
		return
	
	if is_instance_valid(game):
		game.queue_free()
	for i: Node in screens:
		i.queue_free()
	
	var menu_scene: PackedScene = load("uid://4wb77emq8t5p")
	menu = menu_scene.instantiate()
	add_child(menu)
	print_verbose("Opened menu.")


## Открывает игру с меню локальной игры. Закрывает всё остальное.
func open_local_game() -> void:
	if is_instance_valid(game):
		push_error("Game is already opened!")
		return
	
	if is_instance_valid(menu):
		menu.queue_free()
	for i: Node in screens:
		i.queue_free()
	
	var game_scene: PackedScene = load("uid://scqgxynxowrb")
	game = game_scene.instantiate()
	add_child(game)
	game.init_connect_local()
	print_verbose("Opened game with local menu.")


## Открывает экран, указанный в [param screen], регистрируя его в [member screens].
## Возвращает узел этого экрана или [code]null[/code], если такой экран уже открыт.
func open_screen(screen_scene: PackedScene) -> Control:
	var screen: Control = screen_scene.instantiate()
	if has_node(NodePath(screen.name)):
		push_error("Screen %s is already opened!" % screen.name)
		return null
	screen.tree_exited.connect(screens.erase.bind(screen))
	add_child(screen)
	screens.append(screen)
	print_verbose("Opened screen '%s'." % screen.name)
	return screen


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
	#var preffered_renderer: String = ProjectSettings.get_setting_with_override(
			#&"rendering/renderer/rendering_method"
	#)
	var shader_cache: bool = ProjectSettings.get_setting_with_override(
			&"rendering/shader_compiler/shader_cache/enabled"
	)
	override_file.set_value(
			"rendering", "shader_compiler/shader_cache/enabled", shader_cache
	)
	override_file.set_value(
			"rendering", "shader_compiler/shader_cache/enabled.mobile", shader_cache
	)
	#override_file.set_value(
			#"rendering", "rendering_device/pipeline_cache/enable", shader_cache
	#)
	#override_file.set_value(
			#"rendering", "rendering_device/pipeline_cache/enable.mobile", shader_cache
	#)
	#override_file.set_value(
			#"rendering", "renderer/rendering_method", preffered_renderer
	#)
	#override_file.set_value(
			#"rendering", "renderer/rendering_method.mobile", preffered_renderer
	#)
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
			"debug_info",
			Globals.get_setting_bool("debug_info", false)
	)
	Globals.set_setting_float(
			"master_volume",
			Globals.get_setting_float("master_volume", 1.0)
	)
	Globals.set_setting_float(
			"music_volume",
			Globals.get_setting_float("music_volume", 0.7)
	)
	Globals.set_setting_float(
			"sfx_volume",
			Globals.get_setting_float("sfx_volume", 1.0)
	)
	Globals.set_setting_bool(
			"fullscreen",
			Globals.get_setting_bool("fullscreen", not OS.has_feature("pc"))
	)
	Globals.set_setting_bool(
			"preload",
			Globals.get_setting_bool("preload", true)
	)
	Globals.set_setting_bool(
			"aim_dodge",
			Globals.get_setting_bool("aim_dodge", false)
	)
	Globals.set_setting_bool(
			"custom_tracks",
			Globals.get_setting_bool("custom_tracks", OS.has_feature("pc"))
	)
	Globals.set_setting_bool(
			"vibration_damage",
			Globals.get_setting_bool("vibration_damage", false)
	)
	Globals.set_setting_bool(
			"vibration_hit",
			Globals.get_setting_bool("vibration_hit", false)
	)
	Globals.set_setting_bool(
			"smooth_camera",
			Globals.get_setting_bool("smooth_camera", true)
	)


## Устанавливает настройки управления по умолчанию, если их ещё нет.
func setup_controls_settings() -> void:
	var default_input_method: InputMethod = InputMethod.KEYBOARD_AND_MOUSE
	if OS.has_feature("mobile"):
		default_input_method = InputMethod.TOUCH
	Globals.set_controls_int(
			"input_method",
			Globals.get_controls_int("input_method", default_input_method)
	)
	Globals.set_controls_bool(
			"follow_mouse",
			Globals.get_controls_bool("follow_mouse", true)
	)
	Globals.set_controls_bool(
			"joystick_fire",
			Globals.get_controls_bool("joystick_fire", false)
	)
	Globals.set_controls_float(
			"sneak_multiplier",
			Globals.get_controls_float("sneak_multiplier", 0.5)
	)
	Globals.set_controls_bool(
			"square_joystick",
			Globals.get_controls_bool("square_joystick", false)
	)
	Globals.set_controls_float(
			"aim_deadzone",
			Globals.get_controls_float("aim_deadzone", 0.2)
	)
	Globals.set_controls_float(
			"aim_zone",
			Globals.get_controls_float("aim_zone", 0.6)
	)
	
	InputMap.load_from_project_settings()
	for i: StringName in InputMap.get_actions():
		if i.begins_with("ui_"):
			continue
		
		var event: InputEvent = InputMap.action_get_events(i)[0]
		var coded_event_type: ActionEventType
		var coded_event_value: int
		
		var mb := event as InputEventMouseButton
		if mb:
			coded_event_type = ActionEventType.MOUSE_BUTTON
			coded_event_value = mb.button_index
		var key := event as InputEventKey
		if key:
			coded_event_type = ActionEventType.KEY
			coded_event_value = key.physical_keycode
		
		Globals.set_controls_int(
				"action_%s_event_type" % i,
				Globals.get_controls_int("action_%s_event_type" % i, coded_event_type)
		)
		Globals.set_controls_int(
				"action_%s_event_value" % i,
				Globals.get_controls_int("action_%s_event_value" % i, coded_event_value)
		)
	
	#region Настройки управления на телефоне
	Globals.set_controls_int(
			"anchors_preset_health_bar",
			Globals.get_controls_int("anchors_preset_health_bar", Control.PRESET_CENTER_BOTTOM)
	)
	Globals.set_controls_vector2(
			"offsets_lt_health_bar",
			Globals.get_controls_vector2("offsets_lt_health_bar", Vector2(-240, -64))
	)
	Globals.set_controls_vector2(
			"offsets_rb_health_bar",
			Globals.get_controls_vector2("offsets_rb_health_bar", Vector2(240, -16))
	)
	
	Globals.set_controls_int(
			"anchors_preset_additional",
			Globals.get_controls_int("anchors_preset_additional", Control.PRESET_BOTTOM_RIGHT)
	)
	Globals.set_controls_vector2(
			"offsets_lt_additional",
			Globals.get_controls_vector2("offsets_lt_additional", Vector2(-128, -128))
	)
	Globals.set_controls_vector2(
			"offsets_rb_additional",
			Globals.get_controls_vector2("offsets_rb_additional", Vector2(-8, -8))
	)
	
	Globals.set_controls_int(
			"anchors_preset_move_js",
			Globals.get_controls_int("anchors_preset_move_js", Control.PRESET_BOTTOM_LEFT)
	)
	Globals.set_controls_vector2(
			"offsets_lt_move_js",
			Globals.get_controls_vector2("offsets_lt_move_js", Vector2(128, -328))
	)
	Globals.set_controls_vector2(
			"offsets_rb_move_js",
			Globals.get_controls_vector2("offsets_rb_move_js", Vector2(328, -128))
	)
	
	Globals.set_controls_int(
			"anchors_preset_aim_js",
			Globals.get_controls_int("anchors_preset_aim_js", Control.PRESET_BOTTOM_RIGHT)
	)
	Globals.set_controls_vector2(
			"offsets_lt_aim_js",
			Globals.get_controls_vector2("offsets_lt_aim_js", Vector2(-328, -328))
	)
	Globals.set_controls_vector2(
			"offsets_rb_aim_js",
			Globals.get_controls_vector2("offsets_rb_aim_js", Vector2(-128, -128))
	)
	
	Globals.set_controls_int(
			"anchors_preset_weapon",
			Globals.get_controls_int("anchors_preset_weapon", Control.PRESET_CENTER_RIGHT)
	)
	Globals.set_controls_vector2(
			"offsets_lt_weapon",
			Globals.get_controls_vector2("offsets_lt_weapon", Vector2(-288, -232))
	)
	Globals.set_controls_vector2(
			"offsets_rb_weapon",
			Globals.get_controls_vector2("offsets_rb_weapon", Vector2(0, -88))
	)
	
	Globals.set_controls_int(
			"anchors_preset_skill",
			Globals.get_controls_int("anchors_preset_skill", Control.PRESET_CENTER_RIGHT)
	)
	Globals.set_controls_vector2(
			"offsets_lt_skill",
			Globals.get_controls_vector2("offsets_lt_skill", Vector2(-128, -80))
	)
	Globals.set_controls_vector2(
			"offsets_rb_skill",
			Globals.get_controls_vector2("offsets_rb_skill", Vector2(-8, 40))
	)
	
	Globals.set_controls_float(
			"move_joystick_scale",
			Globals.get_controls_float("move_joystick_scale", 1.0)
	)
	Globals.set_controls_float(
			"move_joystick_deadzone",
			Globals.get_controls_float("move_joystick_deadzone", 20.0)
	)
	Globals.set_controls_int(
			"move_joystick_mode",
			Globals.get_controls_int("move_joystick_mode", VirtualJoystick.JoystickMode.DYNAMIC)
	)
	
	Globals.set_controls_float(
			"aim_joystick_scale",
			Globals.get_controls_float("aim_joystick_scale", 1.0)
	)
	Globals.set_controls_float(
			"aim_joystick_deadzone",
			Globals.get_controls_float("aim_joystick_deadzone", 20.0)
	)
	Globals.set_controls_int(
			"aim_joystick_mode",
			Globals.get_controls_int("aim_joystick_type", VirtualJoystick.JoystickMode.DYNAMIC)
	)
	
	Globals.set_controls_vector2(
			"shoot_area",
			Globals.get_controls_vector2("shoot_area", Vector2(640, 256))
	)
	#endregion


## Применяет общие настройки.
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(&"Master"),
			linear_to_db(Globals.get_setting_float("master_volume"))
	)
	AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(&"Music"),
			linear_to_db(Globals.get_setting_float("music_volume"))
	)
	AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(&"SFX"),
			linear_to_db(Globals.get_setting_float("sfx_volume"))
	)
	if Globals.get_setting_bool("fullscreen"):
		if not get_window().mode in [Window.MODE_EXCLUSIVE_FULLSCREEN, Window.MODE_FULLSCREEN]:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		if not get_window().mode in [
			Window.MODE_WINDOWED,
			Window.MODE_MINIMIZED,
			Window.MODE_MAXIMIZED,
		]:
			get_window().mode = Window.MODE_WINDOWED
	if Globals.get_setting_bool("custom_tracks"):
		DirAccess.make_dir_recursive_absolute(music_path)


## Применяет настройки управления.
func apply_controls_settings() -> void:
	Input.emulate_touch_from_mouse = Globals.get_controls_int("input_method") == InputMethod.TOUCH
	
	if not Globals.get_controls_int("input_method") == InputMethod.KEYBOARD_AND_MOUSE:
		return
	for i: StringName in InputMap.get_actions():
		if i.begins_with("ui_"):
			continue
		InputMap.action_erase_events(i)
		
		var coded_event_type: ActionEventType = \
				Globals.get_controls_int("action_%s_event_type" % i) as ActionEventType
		var coded_event_value: int = Globals.get_controls_int("action_%s_event_value" % i)
		var event: InputEvent
		
		match coded_event_type:
			ActionEventType.KEY:
				var key := InputEventKey.new()
				key.physical_keycode = coded_event_value as Key
				event = key
			ActionEventType.MOUSE_BUTTON:
				var mb := InputEventMouseButton.new()
				mb.button_index = coded_event_value as MouseButton
				event = mb
		
		InputMap.action_add_event(i, event)


func _update_window_stretch_aspect() -> void:
	var ratio: float = get_window().size.x / float(get_window().size.y)
	if ratio > MAX_ASPECT_RATIO:
		get_window().content_scale_size = Vector2i(
				roundi(_default_window_content_height * MAX_ASPECT_RATIO),
				_default_window_content_height
		)
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH
	elif ratio < MIN_ASPECT_RATIO:
		get_window().content_scale_size = Vector2i(
				_default_window_content_width,
				roundi(_default_window_content_width / MIN_ASPECT_RATIO),
		)
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
	else:
		get_window().content_scale_size = \
				Vector2i(_default_window_content_width, _default_window_content_height)
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND


func _start_load() -> void:
	$SplashScreen.queue_free()
	($LoadingScreen/AnimationPlayer as AnimationPlayer).play(&"Begin")
	_loading_init()
	await loading_stage_finished
	
	# TODO: а стоит ли это запускать в headless режиме?
	_loading_check_server()
	var success: bool = await loading_stage_finished
	if success:
		# Загрузка данных
		# Синхронизация версии
		pass
	
	_loading_custom_tracks()
	await loading_stage_finished
	
	_loading_preload_resources()
	await loading_stage_finished
	
	_loading_open_menu()
	await loading_stage_finished
	$LoadingScreen.queue_free()
	
	if Globals.headless:
		open_local_game()
		game.create()


func _loading_init() -> void:
	print_verbose("Initializing...")
	_load_status_label.text = "Инициализация..."
	_load_progress_bar.value = 0
	await get_tree().process_frame
	
	Globals.initialize(self)
	if DisplayServer.get_name() == "headless" or OS.has_feature("dedicated_server"):
		print("Running in headless mode.")
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Globals.headless = true
	
	_update_window_stretch_aspect()
	get_window().size_changed.connect(_update_window_stretch_aspect)
	multiplayer.multiplayer_peer = null # Чтобы убрать OfflineMultiplayerPeer
	get_viewport().set_canvas_cull_mask_bit(1, false)
	
	setup_settings()
	apply_settings()
	setup_controls_settings()
	apply_controls_settings()
	
	await get_tree().process_frame
	print_verbose("Done initializing.")
	loading_stage_finished.emit(true)


func _loading_check_server() -> void:
	print_verbose("Checking connection to server...")
	_load_status_label.text = "Проверка соединения с сервером..."
	_load_progress_bar.value = 0
	await get_tree().process_frame
	
	var http := HTTPRequest.new()
	http.timeout = 3.0
	http.request_completed.connect(_on_check_http_request_completed.bind(http))
	add_child(http)
	
	var err: Error = http.request("https://diamondstudiogames.github.io/README.md")
	if err != OK:
		push_warning("Can't connect to server! Error: %s" % error_string(err))
		loading_stage_finished.emit(false)
		http.queue_free()


func _loading_custom_tracks() -> void:
	if not Globals.get_setting_bool("custom_tracks"):
		print_verbose("Not loading custom tracks: disabled.")
		loading_stage_finished.emit.call_deferred(false) # Ждём await
		return
	
	print_verbose("Loading custom tracks...")
	_load_status_label.text = "Загрузка пользовательских треков..."
	_load_progress_bar.value = 0
	await get_tree().process_frame
	
	var dir := DirAccess.open(music_path)
	if not dir:
		push_error("Failed creating DirAccess at path %s. Error: %s." % [
			music_path,
			error_string(DirAccess.get_open_error()),
		])
		loading_stage_finished.emit(false)
		return
	
	var to_load: Dictionary[String, String]
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if to_load.size() >= 20:
			break
		if not dir.current_is_dir():
			for i: String in ALLOWED_MUSIC_FILE_EXTENSIONS:
				if file_name.ends_with(i):
					to_load[dir.get_current_dir().path_join(file_name)] = i
					print_verbose("Found track: %s." % dir.get_current_dir().path_join(file_name))
					break
		file_name = dir.get_next()
	
	var to_load_count: int = to_load.size()
	var counter: int = 0
	var last_ticks: int = Time.get_ticks_msec()
	for i: String in to_load:
		var stream: AudioStream
		var valid := true
		var file := FileAccess.open(i, FileAccess.READ)
		if not file:
			valid = false
			push_error("Failed creating FileAccess at path %s. Error: %s." % [
				i,
				error_string(FileAccess.get_open_error()),
			])
		if valid and file.get_length() > 15 * 1024 * 1024:
			valid = false
		if valid:
			match to_load[i]:
				".mp3":
					var mp3 := AudioStreamMP3.new()
					mp3.data = file.get_buffer(file.get_length())
					if mp3.data.is_empty():
						valid = false
					else:
						mp3.loop = true
						stream = mp3
				".ogg":
					var ogg := AudioStreamOggVorbis.load_from_buffer(
							file.get_buffer(file.get_length())
					)
					if ogg:
						ogg.loop = true
						stream = ogg
					else:
						valid = false
		
		if valid:
			print_verbose("Loaded track: %s." % i)
			loaded_custom_tracks[
				i.get_file().get_basename().left(MAX_MUSIC_FILE_NAME_LENGTH)
			] = stream
		else:
			print_verbose("Track %s is invalid." % i)
		
		_load_progress_bar.value = 100.0 * counter / to_load_count
		counter += 1
		if Time.get_ticks_msec() - last_ticks > 16:
			await get_tree().process_frame
			last_ticks = Time.get_ticks_msec()
	
	print_verbose("Done loading custom tracks.")
	loading_stage_finished.emit(true)


func _loading_preload_resources() -> void:
	if not Globals.get_setting_bool("preload"):
		print_verbose("Not preloading resources: disabled.")
		loading_stage_finished.emit.call_deferred(false) # Ждём await
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


func _on_check_http_request_completed(result: HTTPRequest.Result,
		response_code: HTTPClient.ResponseCode, _headers: PackedStringArray, 
		_body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Connect to server: result is not Success! Result: %d" % result)
		loading_stage_finished.emit(false)
		return
	if response_code != HTTPClient.RESPONSE_OK:
		push_warning(
				"Connect to server: response code is not 200! Response code: %d" % response_code
		)
		loading_stage_finished.emit(false)
		return
	print_verbose("Connection success.")
	loading_stage_finished.emit(true)
