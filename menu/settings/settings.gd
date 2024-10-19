extends Control

@export_multiline var help_messages: Array[String]

func _ready() -> void:
	show_section("General")
	# Конфигурация настроек


func show_section(section_name: String) -> void:
	for i: Control in %SectionsContainer.get_children():
		i.hide()
	
	(%SectionsContainer.get_node(NodePath(section_name)) as Control).show()


func show_help(help_idx: int) -> void:
	($HelpDialog as AcceptDialog).dialog_text = help_messages[help_idx]
	($HelpDialog as Window).popup_centered()


func _on_exit_pressed() -> void:
	Globals.main.close_screen(self)
