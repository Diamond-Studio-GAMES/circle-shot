class_name EventUI
extends Node


var _player: Player
var _status_tween: Tween
@onready var chat: Chat = $Main/ChatPanel
@onready var _health_bar: TextureProgressBar = $Main/Player/HealthBar
@onready var _health_text: Label = $Main/Player/HealthBar/Label
@onready var _tint_anim: AnimationPlayer = $Main/PlayerTint/AnimationPlayer
@onready var _status_label: RichTextLabel = $Main/StatusLabel
@onready var _chat_button: BaseButton = chat.get_node(chat.chat_button_path)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"close_chat") and _chat_button.button_pressed:
		_chat_button.button_pressed = false


@rpc("authority", "call_local", "reliable", 5)
func show_status(text: String, duration: float = 2.0) -> void:
	_status_label.self_modulate = Color.WHITE
	_status_label.text = "[center]%s[/center]" % text
	if is_instance_valid(_status_tween):
		_status_tween.kill()
	_status_tween = create_tween()
	_status_tween.tween_interval(duration)
	_status_tween.tween_property(_status_label, "self_modulate", Color.TRANSPARENT, 0.5)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"chat") and not _chat_button.button_pressed:
		_chat_button.button_pressed = true


func _on_leave_game_pressed() -> void:
	Globals.main.game.close()


func _on_local_player_created(player: Player) -> void:
	($Main/Player as Control).show()
	_on_player_health_changed(player.max_health, player.max_health)
	_tint_anim.play(&"RESET")
	
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	
	_player = player


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if new_value > _health_bar.max_value:
		_health_bar.max_value = new_value
	_health_bar.value = new_value
	_health_text.text = "%d/%d" % [_health_bar.value, _health_bar.max_value]
	if new_value < old_value:
		_tint_anim.play(&"Hurt")
	if new_value < _health_bar.max_value * 0.34:
		($Main/Player/BloodVignette as Control).show()
	else:
		($Main/Player/BloodVignette as Control).hide()


func _on_player_died(_who: int) -> void:
	($Main/Player as Control).hide()
	_tint_anim.play(&"Death")
