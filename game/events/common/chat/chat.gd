class_name Chat
extends Control

## Чат для общения.
##
## Используйте [member players_names] и [member players_teams] (второе необязательно)
## для регистрации игроков перед тем, как они начнут отправлять сообщения.

## Издаётся когда в чате появляется новое сообщение с текстом [param message].
signal message_posted(message: String)
## Максимальная длина сообщения.
const MAX_MESSAGE_LENGTH: int = 80
## Путь к кнопке, которая будет моргать при новом сообщении.
@export_node_path("Button") var chat_button_path: NodePath
## Словарь имён игроков, в формате <ID> - <имя>.
var players_names: Dictionary[int, String]
## Словарь команд игроков, в формате <ID> - <команда>. Используется для раскраски ников.
var players_teams: Dictionary[int, int]
@onready var _chat_button: Button = get_node(chat_button_path)
@onready var _messages: RichTextLabel = $VBoxContainer/Messages
@onready var _chat_edit: LineEdit = $VBoxContainer/HBoxContainer/LineEdit


## Постит сообщение. Должно вызываться только сервером.
@rpc("call_local", "authority", "reliable", 5)
func post_message(message: String) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	_messages.append_text(message + '\n')
	message_posted.emit(message)
	print_verbose("Posted message: %s" % message)
	if not visible:
		var tween: Tween = create_tween()
		tween.tween_property(_chat_button, ^"self_modulate", Color.GREEN, 0.25)
		tween.tween_property(_chat_button, ^"self_modulate", Color.WHITE, 0.25)


## Очищает чат.
func clear_chat() -> void:
	_messages.text = ""


## Отправляет набранное сообщение. Автоматически очищает от лишних пробелов и прочих знаков.
func send_message() -> void:
	var message: String = _chat_edit.text.strip_edges().strip_escapes()
	_chat_edit.clear()
	_chat_button.grab_focus() # TODO: Убрать эту шарманку в новом дев билде и заменить на edit
	_chat_edit.grab_focus.call_deferred()
	
	if message.is_empty():
		return
	if multiplayer.is_server():
		_request_post_message(message)
	else:
		_request_post_message.rpc_id(1, message)
	print_verbose("Sent message: %s" % message)


@rpc("any_peer", "call_remote", "reliable", 5)
func _request_post_message(message: String) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if not players_names.has(sender_id):
		push_warning("Received post message request from unknown peer (%d)." % sender_id)
		return
	
	message = message.strip_edges().strip_escapes().replace("[", "[lb]")
	if message.is_empty():
		return
	if message.length() > MAX_MESSAGE_LENGTH:
		push_warning("Client %d posted message with length %d, which is more than allowed (%d)." % [
			sender_id,
			message.length(),
			MAX_MESSAGE_LENGTH,
		])
		message = message.left(MAX_MESSAGE_LENGTH)
	if players_teams.has(sender_id):
		message = "[color=#%s]%s[/color]: %s" % [
			Entity.TEAM_COLORS[players_teams[sender_id]].to_html(false),
			players_names[sender_id],
			message,
		]
	else:
		message = "[color=red]%s[/color]: %s" % [players_names[sender_id], message]
	post_message.rpc(message)


func _on_chat_toggled(toggled_on: bool) -> void:
	visible = toggled_on
	if toggled_on:
		_chat_edit.grab_focus()
