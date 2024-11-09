extends Control

@export_multiline var help_messages: Array[String]
var _override_file := ConfigFile.new()

func _ready() -> void:
	show_section("General")
	
	# Конфигурация настроек
	_override_file.load("user://engine_settings.cfg")
	#var preffered_renderer: int
	#if _override_file.get_value("rendering", "renderer/rendering_method") == "mobile":
		#preffered_renderer = 0
	#else:
		#preffered_renderer = 1
	#(%RendererOptions as OptionButton).selected = preffered_renderer
	var shader_cache: bool = \
			_override_file.get_value("rendering", "shader_compiler/shader_cache/enabled")
	(%ShaderCacheCheck as Button).set_pressed_no_signal(shader_cache)
	#if RenderingServer.get_rendering_device():
		#(%CurrentRenderer as Label).text = "Текущий отрисовщик: Vulkan"
	#else:
		#(%CurrentRenderer as Label).text = "Текущий отрисовщик: OpenGL"
	
	(%HitMarkersCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("hit_markers"))
	(%ShowMinimapCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("minimap"))
	(%ShowDebugCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("debug_info"))
	(%MasterVolumeSlider as HSlider).value = Globals.get_setting_float("master_volume")
	(%MusicVolumeSlider as HSlider).value = Globals.get_setting_float("music_volume")
	(%SFXVolumeSlider as HSlider).value = Globals.get_setting_float("sfx_volume")
	(%FullscreenCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("fullscreen"))
	(%PreloadCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("preload"))
	(%DodgeOptions as OptionButton).selected = int(Globals.get_setting_bool("aim_dodge"))
	(%InputOptions as OptionButton).selected = Globals.get_controls_int("input_method")
	_toggle_input_method_settings_visibility(Globals.get_controls_int("input_method"))
	(%FollowMouseCheck as Button).set_pressed_no_signal(Globals.get_controls_bool("follow_mouse"))
	(%FireModeOptions as OptionButton).selected = int(Globals.get_controls_bool("joystick_fire"))
	(%SquareCheck as Button).set_pressed_no_signal(Globals.get_controls_bool("square_joystick"))
	(%SneakSlider as HSlider).value = Globals.get_controls_float("sneak_multiplier")
	(%VibDamageCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("vibration_damage"))
	(%VibHitCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("vibration_hit"))
	
	# Кастомные треки
	(%CustomTracksCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("custom_tracks"))
	_on_custom_tracks_check_toggled((%CustomTracksCheck as Button).button_pressed)
	(%CustomTracksPath as Label).text = "Путь к папке с треками: %s" % Globals.main.music_path
	if not Globals.main.loaded_custom_tracks.is_empty():
		for i: Node in %LoadedTracks.get_children():
			i.queue_free()
		
		for i: String in Globals.main.loaded_custom_tracks:
			var label := Label.new()
			label.text = i
			%LoadedTracks.add_child(label)
	
	if OS.has_feature("mobile"):
		(%FullscreenCheck as CheckButton).set_pressed_no_signal(true)
		(%FullscreenCheck as CheckButton).self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		(%FullscreenCheck as CheckButton).disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action(&"fullscreen") and event.is_pressed():
		(%FullscreenCheck as CheckButton).set_pressed_no_signal(
				Globals.get_setting_bool("fullscreen")
		)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_exit_pressed()


func show_section(section_name: String) -> void:
	for i: Control in %Sections.get_children():
		i.hide()
	
	(%Sections.get_node(NodePath(section_name)) as Control).show()


func show_help(help_idx: int) -> void:
	($HelpDialog as AcceptDialog).dialog_text = help_messages[help_idx]
	($HelpDialog as Window).popup_centered()


func remove_recursive(path: String) -> void:
	var dir_access := DirAccess.open(path)
	if dir_access:
		dir_access.list_dir_begin()
		var dirs_to_remove: Array[String]
		var files_to_remove: Array[String]
		var file_name: String = dir_access.get_next()
		
		while not file_name.is_empty():
			if dir_access.current_is_dir():
				dirs_to_remove.append(file_name)
			else:
				files_to_remove.append(file_name)
			file_name = dir_access.get_next()
		
		for i: String in files_to_remove:
			dir_access.remove(i)
		for i: String in dirs_to_remove:
			remove_recursive(dir_access.get_current_dir().path_join(i))
		
		dir_access.remove(dir_access.get_current_dir())


func _toggle_input_method_settings_visibility(method: Main.InputMethod) -> void:
	(%KeyboardSettings as Control).hide()
	(%TouchSettings as Control).hide()
	match method:
		Main.InputMethod.KEYBOARD_AND_MOUSE:
			(%KeyboardSettings as Control).show()
		Main.InputMethod.TOUCH:
			(%TouchSettings as Control).show()


func _on_exit_pressed() -> void:
	queue_free()


func _on_hit_markers_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("hit_markers", toggled_on)


func _on_show_minimap_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("minimap", toggled_on)


func _on_show_debug_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("debug_info", toggled_on)


func _on_master_volume_slider_value_changed(value: float) -> void:
	Globals.set_setting_float("master_volume", value)
	Globals.main.apply_settings()


func _on_music_volume_slider_value_changed(value: float) -> void:
	Globals.set_setting_float("music_volume", value)
	Globals.main.apply_settings()


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	Globals.set_setting_float("sfx_volume", value)
	Globals.main.apply_settings()


func _on_shader_cache_check_toggled(toggled_on: bool) -> void:
	_override_file.set_value(
			"rendering", "shader_compiler/shader_cache/enabled", toggled_on
	)
	_override_file.set_value(
			"rendering", "shader_compiler/shader_cache/enabled.mobile", toggled_on
	)
	_override_file.set_value(
			"rendering", "rendering_device/pipeline_cache/enable", toggled_on
	)
	_override_file.set_value(
			"rendering", "rendering_device/pipeline_cache/enable.mobile", toggled_on
	)
	_override_file.save("user://engine_settings.cfg")


func _on_renderer_options_item_selected(index: int) -> void:
	var new_renderer: String = "gl_compatibility" if index != 0 else "mobile"
	_override_file.set_value(
			"rendering", "renderer/rendering_method", new_renderer
	)
	_override_file.set_value(
			"rendering", "renderer/rendering_method.mobile", new_renderer
	)
	_override_file.save("user://engine_settings.cfg")


func _on_clear_shader_cache_pressed() -> void:
	remove_recursive("user://shader_cache")
	remove_recursive("user://vulkan")
	if OS.has_feature("pc"):
		OS.set_restart_on_exit(true)
	get_tree().quit()


func _on_reset_data_dialog_confirmed() -> void:
	remove_recursive("user://")
	if OS.has_feature("pc"):
		OS.set_restart_on_exit(true)
	get_tree().quit()


func _on_reset_settings_dialog_confirmed() -> void:
	Globals.save_file.erase_section(Globals.SETTINGS_SAVE_FILE_SECTION)
	Globals.save_file.erase_section(Globals.CONTROLS_SAVE_FILE_SECTION)
	DirAccess.remove_absolute("user://engine_settings.cfg")
	Globals.main.setup_settings()
	Globals.main.apply_settings()
	Globals.main.setup_controls_settings()
	Globals.main.apply_controls_settings()
	
	name = &"OldSettings"
	queue_free()
	Globals.main.open_screen(load("uid://c2leb2h0qjtmo") as PackedScene)


func _on_change_name_pressed() -> void:
	($NameDialog as Window).title = \
			"Смена имени (текущее: %s)" % Globals.get_string("player_name")
	($NameDialog as AcceptDialog).popup_centered()


func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("fullscreen", toggled_on)
	Globals.main.apply_settings()


func _on_dodge_options_item_selected(index: int) -> void:
	Globals.set_setting_bool("aim_dodge", bool(index))


func _on_input_options_item_selected(index: int) -> void:
	Globals.set_controls_int("input_method", index)
	Globals.main.apply_controls_settings()
	_toggle_input_method_settings_visibility(index)


func _on_follow_mouse_check_toggled(toggled_on: bool) -> void:
	Globals.set_controls_bool("follow_mouse", toggled_on)


func _on_reset_controls_dialog_confirmed() -> void:
	Globals.save_file.erase_section(Globals.CONTROLS_SAVE_FILE_SECTION)
	Globals.main.setup_controls_settings()
	Globals.main.apply_controls_settings()
	
	name = &"OldSettings"
	queue_free()
	Globals.main.open_screen(load("uid://c2leb2h0qjtmo") as PackedScene)


func _on_custom_tracks_check_toggled(toggled_on: bool) -> void:
	if toggled_on and OS.has_feature("android"):
		var perms: PackedStringArray = OS.get_granted_permissions()
		if not (
				perms.has("android.permission.READ_MEDIA_AUDIO") \
				or perms.has("android.permission.READ_EXTERNAL_STORAGE")
				or perms.has("android.permission.WRITE_EXTERNAL_STORAGE")
		):
			OS.request_permissions()
			get_tree().on_request_permissions_result.connect(
					_on_request_permissions_result, CONNECT_ONE_SHOT
			)
	(%CustomTracksSettings as Control).visible = toggled_on
	Globals.set_setting_bool("custom_tracks", toggled_on)
	Globals.main.apply_settings()


func _on_request_permissions_result(permission: String, granted: bool) -> void:
	print_verbose("Permission %s granted: %s." % [permission, str(granted)])
	var lambda: Callable = func(value: bool) -> void:
		(%CustomTracksCheck as Button).button_pressed = value
	lambda.call_deferred(granted)


func _on_preload_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("preload", toggled_on)


func _on_fire_mode_options_item_selected(index: int) -> void:
	Globals.set_controls_bool("joystick_fire", bool(index))


func _on_square_check_toggled(toggled_on: bool) -> void:
	Globals.set_controls_bool("square_joystick", toggled_on)


func _on_sneak_slider_value_changed(value: float) -> void:
	Globals.set_controls_float("sneak_multiplier", value)
	(%SneakValue as Label).text = "x%.2f" % value


func _on_vib_hit_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("vibration_hit", toggled_on)


func _on_vib_damage_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("vibration_damage", toggled_on)
