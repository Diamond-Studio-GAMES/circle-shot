class_name GameUI
extends Node


var _player: Player
var _status_tween: Tween
@onready var chat: Chat = $Main/ChatPanel
@onready var _health_bar: TextureProgressBar = $Main/Player/HealthBar
@onready var _health_text: Label = $Main/Player/HealthBar/Label
@onready var _tint_anim: AnimationPlayer = $Main/PlayerTint/AnimationPlayer
@onready var _ammo_text: Label = $Main/Player/CurrentWeapon/Label
@onready var _status_label: RichTextLabel = $Main/StatusLabel
@onready var _chat_button: BaseButton = chat.get_node(chat.chat_button_path)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("close_chat") and _chat_button.button_pressed:
		_chat_button.button_pressed = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_weapon"):
		if ($Main/Player/WeaponSelection as Control).visible:
			close_weapon_selection()
		else:
			open_weapon_selection()
	elif event.is_action_pressed("weapon_light"):
		select_weapon(Weapon.Type.LIGHT)
	elif event.is_action_pressed("weapon_heavy"):
		select_weapon(Weapon.Type.HEAVY)
	elif event.is_action_pressed("weapon_support"):
		select_weapon(Weapon.Type.SUPPORT)
	elif event.is_action_pressed("weapon_melee"):
		select_weapon(Weapon.Type.MELEE)
	elif event.is_action_pressed("chat") and not _chat_button.button_pressed:
		_chat_button.button_pressed = true


@rpc("authority", "call_remote", "reliable", 5)
func show_status(text: String, duration: float = 2.0) -> void:
	_status_label.self_modulate = Color.WHITE
	_status_label.text = "[center]%s[/center]" % text
	if is_instance_valid(_status_tween):
		_status_tween.kill()
	_status_tween = create_tween()
	_status_tween.tween_interval(duration)
	_status_tween.tween_property(_status_label, "self_modulate", Color.TRANSPARENT, 0.5)


func open_weapon_selection() -> void:
	($Main/Player/WeaponSelection as Control).show()
	($Main/Player/CurrentWeapon as Control).hide()


func close_weapon_selection() -> void:
	($Main/Player/WeaponSelection as Control).hide()
	($Main/Player/CurrentWeapon as Control).show()


func select_weapon(type: Weapon.Type) -> void:
	close_weapon_selection()
	if is_instance_valid(_player):
		_player.request_change_weapon(type)


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
	player.ammo_text_updated.connect(_on_ammo_text_updated)
	player.weapon_changed.connect(_on_weapon_changed)
	
	($Main/Player/WeaponSelection/LightWeapon/Icon as TextureRect).texture = \
			load(Global.items_db.weapons_light[player.weapons_data[0]].image_path) as Texture2D
	($Main/Player/WeaponSelection/LightWeapon/Label as Label).text = \
			Global.items_db.weapons_light[player.weapons_data[0]].weapon_name
	($Main/Player/WeaponSelection/HeavyWeapon/Icon as TextureRect).texture = \
			load(Global.items_db.weapons_heavy[player.weapons_data[1]].image_path) as Texture2D
	($Main/Player/WeaponSelection/HeavyWeapon/Label as Label).text = \
			Global.items_db.weapons_heavy[player.weapons_data[1]].weapon_name
	($Main/Player/WeaponSelection/SupportWeapon/Icon as TextureRect).texture = \
			load(Global.items_db.weapons_support[player.weapons_data[2]].image_path) as Texture2D
	($Main/Player/WeaponSelection/SupportWeapon/Label as Label).text = \
			Global.items_db.weapons_support[player.weapons_data[2]].weapon_name
	($Main/Player/WeaponSelection/MeleeWeapon/Icon as TextureRect).texture = \
			load(Global.items_db.weapons_melee[player.weapons_data[3]].image_path) as Texture2D
	($Main/Player/WeaponSelection/MeleeWeapon/Label as Label).text = \
			Global.items_db.weapons_melee[player.weapons_data[3]].weapon_name
	_on_weapon_changed(Weapon.Type.LIGHT)
	
	_player = player


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


func _on_ammo_text_updated(text: String) -> void:
	_ammo_text.text = text


func _on_weapon_changed(to: Weapon.Type) -> void:
	match to:
		Weapon.Type.LIGHT:
			($Main/Player/CurrentWeapon/Icon as TextureRect).texture = \
					($Main/Player/WeaponSelection/LightWeapon/Icon as TextureRect).texture
		Weapon.Type.HEAVY:
			($Main/Player/CurrentWeapon/Icon as TextureRect).texture = \
					($Main/Player/WeaponSelection/HeavyWeapon/Icon as TextureRect).texture
		Weapon.Type.SUPPORT:
			($Main/Player/CurrentWeapon/Icon as TextureRect).texture = \
					($Main/Player/WeaponSelection/SupportWeapon/Icon as TextureRect).texture
		Weapon.Type.MELEE:
			($Main/Player/CurrentWeapon/Icon as TextureRect).texture = \
					($Main/Player/WeaponSelection/MeleeWeapon/Icon as TextureRect).texture
