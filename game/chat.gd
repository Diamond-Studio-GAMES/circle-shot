class_name Chat
extends Control

@export_node_path("Button") var chat_button_path: NodePath
var _prefix: String
@onready var _chat_button: Button = get_node(chat_button_path)
@onready var _messages: RichTextLabel = $VBoxContainer/Messages


@rpc("any_peer", "call_remote", "reliable", 5)
func _request_post_message(message: String) -> void:
	if not multiplayer.is_server():
		return
	post_message.rpc(message)


@rpc("call_local", "authority", "reliable", 5)
func post_message(message: String) -> void:
	_messages.append_text(message + '\n')
	if not visible:
		var tween := create_tween()
		tween.tween_property(_chat_button, ^"self_modulate", Color.GREEN, 0.25)
		tween.tween_property(_chat_button, ^"self_modulate", Color.WHITE, 0.25)


func create_prefix_from_name(player_name: String) -> void:
	_prefix = "[color=red]%s[/color]: " % player_name


func clear_chat() -> void:
	_messages.text = ""


func _on_local_player_created(player: Player) -> void:
	_prefix = "[color=#%s]%s[/color]: " % [Game.TEAM_COLORS[player.team].to_html(false), player.player_name]


func _on_chat_toggled(toggled_on: bool) -> void:
	visible = toggled_on
	if toggled_on:
		($VBoxContainer/LineEdit as Control).grab_focus()


func _on_line_edit_text_submitted(new_text: String) -> void:
	var message := _prefix + new_text.strip_edges().strip_escapes().replace("[", "[lb]")
	if message == _prefix:
		return
	if multiplayer.is_server():
		_request_post_message(message)
	else:
		_request_post_message.rpc_id(1, message)
