extends Control


@export var messages_visible_limit: int = 4
@export var messages_visible_time := 3.0
@onready var _chat: Chat = $"../ChatPanel"
@onready var _chat_button: BaseButton = _chat.get_node(_chat.chat_button_path)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"close_chat") and _chat_button.button_pressed:
		_chat_button.button_pressed = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"chat") and not _chat_button.button_pressed:
		_chat_button.button_pressed = true


func _on_message_posted(message: String) -> void:
	if _chat.visible:
		return
	if get_child_count() >= messages_visible_limit:
		get_child(0).queue_free()
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.scroll_active = false
	rtl.shortcut_keys_enabled = false
	rtl.fit_content = true
	rtl.text = message
	rtl.add_theme_constant_override(&"outline_size", 4)
	add_child(rtl)
	var tween: Tween = rtl.create_tween()
	tween.tween_interval(messages_visible_time)
	tween.tween_property(rtl, ^"modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(rtl.queue_free)


func _on_chat_toggled(toggled_on: bool) -> void:
	if toggled_on:
		for i: Node in get_children():
			i.queue_free()
