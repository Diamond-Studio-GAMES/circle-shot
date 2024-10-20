extends Control

@export_multiline var help_messages: Array[String]
var _override_file := ConfigFile.new()

func _ready() -> void:
	show_section("General")
	
	# Конфигурация настроек
	_override_file.load("user://engine_settings.cfg")
	var preffered_renderer: int
	if _override_file.get_value("rendering", "renderer/rendering_method") == "mobile":
		preffered_renderer = 0
	else:
		preffered_renderer = 1
	(%RendererOptions as OptionButton).selected = preffered_renderer
	var shader_cache: bool = \
			_override_file.get_value("rendering", "shader_compiler/shader_cache/enabled")
	(%ShaderCacheCheck as Button).set_pressed_no_signal(shader_cache)
	
	if RenderingServer.get_rendering_device():
		(%CurrentRenderer as Label).text = "Текущий отрисовщик: Vulkan"
	else:
		(%CurrentRenderer as Label).text = "Текущий отрисовщик: OpenGL"
	(%HitMarkersCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("hit_markers"))
	(%ShowMinimapCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("minimap"))
	(%ShowDebugCheck as Button).set_pressed_no_signal(Globals.get_setting_bool("debug_data"))
	(%MasterVolumeSlider as HSlider).value = Globals.get_setting_float("master_volume")
	(%MusicVolumeSlider as HSlider).value = Globals.get_setting_float("music_volume")
	(%SFXVolumeSlider as HSlider).value = Globals.get_setting_float("sfx_volume")


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


func _on_exit_pressed() -> void:
	Globals.main.close_screen(self)


func _on_hit_markers_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("hit_markers", toggled_on)


func _on_show_minimap_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("minimap", toggled_on)


func _on_show_debug_check_toggled(toggled_on: bool) -> void:
	Globals.set_setting_bool("debug_data", toggled_on)


func _on_master_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(value))


func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), linear_to_db(value))


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), linear_to_db(value))


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
	OS.set_restart_on_exit(true)
	get_tree().quit()


func _on_reset_data_dialog_confirmed() -> void:
	remove_recursive("user://")
	OS.set_restart_on_exit(true)
	get_tree().quit()


func _on_reset_settings_dialog_confirmed() -> void:
	Globals.save_file.erase_section(Globals.SETTINGS_SAVE_FILE_SECTION)
	Globals.save_file.erase_section(Globals.CONTROLS_SAVE_FILE_SECTION)
	DirAccess.remove_absolute("user://engine_settings.cfg")
	Globals.main.setup_settings()
	Globals.main.setup_controls_settings()
	get_parent().remove_child(self)
	Globals.main.close_screen(self)
	Globals.main.open_settings()


func _on_change_name_pressed() -> void:
	($NameDialog as Window).title = \
			"Смена имени (текущее: %s)" % Globals.get_string("player_name")
	($NameDialog as AcceptDialog).popup_centered()
