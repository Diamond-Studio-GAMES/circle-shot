extends Control

@export_multiline var help_messages: Array[String]

func _ready() -> void:
	show_section("General")
	
	# Конфигурация настроек
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
	for i: Control in %SectionsContainer.get_children():
		i.hide()
	
	(%SectionsContainer.get_node(NodePath(section_name)) as Control).show()


func show_help(help_idx: int) -> void:
	($HelpDialog as AcceptDialog).dialog_text = help_messages[help_idx]
	($HelpDialog as Window).popup_centered()


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
