class_name GameUI
extends CanvasLayer

@onready var _health_bar: TextureProgressBar = $Main/Player/HealthBar
@onready var _health_text: Label = $Main/Player/HealthBar/Label
@onready var _tint_anim: AnimationPlayer = $Main/PlayerTint/AnimationPlayer


func _on_leave_game_pressed() -> void:
	(get_tree().current_scene as Shooter).close_connection()


func _on_local_player_created(player: Player) -> void:
	($Main/Player as Control).show()
	_health_bar.max_value = 100
	_health_bar.value = 100
	_health_text.text = "100/100"
	($Main/Player/BloodVignette as Control).hide()
	_tint_anim.play("RESET")
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if new_value > _health_bar.max_value:
		_health_bar.max_value = new_value
	_health_bar.value = new_value
	_health_text.text = "%d/%d" % [_health_bar.value, _health_bar.max_value]
	if new_value < old_value:
		_tint_anim.play("Hurt")
		if new_value < _health_bar.max_value * 0.33:
			($Main/Player/BloodVignette as Control).show()


func _on_player_died(_who: int) -> void:
	($Main/Player as Control).hide()
	_tint_anim.play("Death")
