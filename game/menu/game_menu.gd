class_name GameMenu
extends Control


signal game_create_requested
signal game_join_requested(ip: String)
signal game_leave_requested
signal game_start_requested(game: int, map: int)
var selected_game := 0
var selected_map := 0
var selected_light_weapon := 0
var selected_heavy_weapon := 0
var selected_support_weapon := 0
var selected_melee_weapon := 0
var selected_skin := 0
var _players := {}
var _player_admin_id := -1
@onready var _ip_dialog: ConfirmationDialog = $IPDialog
@onready var _ip_edit: LineEdit = $IPDialog/LineEdit
@onready var _status: Label = $Base/Centering/Main/Status
@onready var _players_container: GridContainer = $Base/Centering/Lobby/Panel/Players
@onready var _item_selector: ItemSelector = $ItemSelector


func _ready() -> void:
	($Base/Centering/Main/Name/LineEdit as LineEdit).text = Global.get_string("player_name", "Колобок")
	selected_skin = Global.get_int("selected_skin")
	selected_light_weapon = Global.get_int("selected_light_weapon")
	selected_heavy_weapon = Global.get_int("selected_heavy_weapon")
	selected_support_weapon = Global.get_int("selected_support_weapon")
	selected_melee_weapon = Global.get_int("selected_melee_weapon")
	_update_weapons_and_skin()
	_update_game_and_map()
	_ip_dialog.register_text_enter($IPDialog/LineEdit as LineEdit)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	if Global.HEADLESS:
		print("Creating server on headless...")
		_on_create_pressed.call_deferred()


## Возвращает данные в виде [type Array] со следующим содержимым: [br]
## Индекс [code]0[/code]: имя игрока,[br]
## Индекс [code]1[/code]: выбранный скин[br]
## Индекс [code]2[/code], [code]3[/code], [code]4[/code] и [code]5[/code]:
## выбранные лёгкое, тяжёлое, ближнее оружия и оружие поддержки
func get_player_data() -> Array:
	return [
		_get_player_name(),
		selected_skin,
		selected_light_weapon,
		selected_heavy_weapon,
		selected_support_weapon,
		selected_melee_weapon,
	]


func create_error_dialog(text: String, code := -1) -> void:
	if code > 0:
		text += " Код ошибки: %d" % code
	($ErrorDialog as AcceptDialog).dialog_text = text
	($ErrorDialog as AcceptDialog).popup_centered()


@rpc("reliable")
func _add_player_entry(id: int, player_name: String) -> void:
	var label := Label.new()
	label.text = player_name
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.name = str(id)
	if id == multiplayer.get_unique_id():
		label.text += " (Ты)"
	_players_container.add_child(label)


@rpc("reliable")
func _delete_player_entry(id: int) -> void:
	_players_container.get_node(str(id)).queue_free()


@rpc("any_peer", "reliable")
func _register_new_player(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		id = 1 # Локально от сервера
	for i: int in _players:
		_add_player_entry.rpc_id(id, i, _players[i])
	_set_environment.rpc_id(id, selected_game, selected_map)
	_players[id] = player_name
	($ChatPanel as Chat).post_message.rpc("Игра: Игрок [color=green]%s[/color] подключился!" % player_name)
	if _players.size() == 1:
		if id == 1:
			_set_admin(true)
		else:
			_set_admin.rpc_id(id, true)
		_player_admin_id = id
	else:
		_set_admin.rpc_id(id, false)
	_add_player_entry.rpc(id, player_name)
	if not Global.HEADLESS:
		_add_player_entry(id, player_name)


@rpc("reliable")
func _set_admin(admin: bool) -> void:
	($Base/Centering/Lobby/AdminPanel as HBoxContainer).visible = admin
	($Base/Centering/Lobby/ClientHint as Label).visible = not admin
	if admin:
		_request_set_environment(Global.get_int("selected_game"), Global.get_int("selected_map"))
	else:
		($Base/Centering/Lobby/ClientHint as Label).text = "Начать игру может только хост."


@rpc("any_peer", "reliable")
func _request_set_environment(game_id: int, map_id: int) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if sender_id != _player_admin_id:
		return
	_set_environment.rpc(game_id, map_id)


@rpc("call_local", "reliable")
func _set_environment(game_id: int, map_id: int) -> void:
	selected_game = game_id
	selected_map = map_id
	_update_game_and_map()


@rpc("any_peer", "reliable")
func _request_start_game() -> void:
	if not multiplayer.is_server():
		return
	var id: int = multiplayer.get_remote_sender_id()
	if id == 0:
		id = 1
	if id != _player_admin_id:
		return
	_start_game.rpc(selected_game, selected_map)


@rpc("call_local", "reliable")
func _start_game(game_id: int, map_id: int) -> void:
	game_start_requested.emit(game_id, map_id)


func _update_game_and_map() -> void:
	var game: GameConfig = Global.items_db.games[selected_game]
	($Base/Centering/Lobby/Environment/Game as TextureRect).texture = load(game.image_path) as Texture2D
	($Base/Centering/Lobby/Environment/Game/Container/Name as Label).text = game.game_name
	($Base/Centering/Lobby/Environment/Game/Container/Description as Label).text = game.game_description
	Global.set_int("selected_game", selected_game)
	
	($Base/Centering/Lobby/Environment/Map as TextureRect).texture = \
			load(game.maps[selected_map].image_path) as Texture2D
	($Base/Centering/Lobby/Environment/Map/Container/Name as Label).text = game.maps[selected_map].map_name
	($Base/Centering/Lobby/Environment/Map/Container/Description as Label).text = \
			game.maps[selected_map].map_description
	Global.set_int("selected_map", selected_map)


func _update_weapons_and_skin() -> void:
	var light_weapon: WeaponConfig = Global.items_db.weapons_light[selected_light_weapon]
	($Base/Centering/Lobby/Player/LightWeapon/Name as Label).text = light_weapon.weapon_name
	($Base/Centering/Lobby/Player/LightWeapon/RarityFill as ColorRect).color = \
			ItemsDB.RARITY_COLORS[light_weapon.rarity]
	($Base/Centering/Lobby/Player/LightWeapon as TextureRect).texture = \
			load(light_weapon.image_path) as Texture2D
	Global.set_int("selected_light_weapon", selected_light_weapon)
	
	var heavy_weapon: WeaponConfig = Global.items_db.weapons_heavy[selected_heavy_weapon]
	($Base/Centering/Lobby/Player/HeavyWeapon/Name as Label).text = heavy_weapon.weapon_name
	($Base/Centering/Lobby/Player/HeavyWeapon/RarityFill as ColorRect).color = \
			ItemsDB.RARITY_COLORS[heavy_weapon.rarity]
	($Base/Centering/Lobby/Player/HeavyWeapon as TextureRect).texture = \
			load(heavy_weapon.image_path) as Texture2D
	Global.set_int("selected_heavy_weapon", selected_heavy_weapon)
	
	var support_weapon: WeaponConfig = Global.items_db.weapons_support[selected_support_weapon]
	($Base/Centering/Lobby/Player/SupportWeapon/Name as Label).text = support_weapon.weapon_name
	($Base/Centering/Lobby/Player/SupportWeapon/RarityFill as ColorRect).color = \
			ItemsDB.RARITY_COLORS[support_weapon.rarity]
	($Base/Centering/Lobby/Player/SupportWeapon as TextureRect).texture = \
			load(support_weapon.image_path) as Texture2D
	Global.set_int("selected_support_weapon", selected_support_weapon)
	
	var melee_weapon: WeaponConfig = Global.items_db.weapons_melee[selected_melee_weapon]
	($Base/Centering/Lobby/Player/MeleeWeapon/Name as Label).text = melee_weapon.weapon_name
	($Base/Centering/Lobby/Player/MeleeWeapon/RarityFill as ColorRect).color = \
			ItemsDB.RARITY_COLORS[melee_weapon.rarity]
	($Base/Centering/Lobby/Player/MeleeWeapon as TextureRect).texture = \
			load(melee_weapon.image_path) as Texture2D
	Global.set_int("selected_melee_weapon", selected_melee_weapon)
	
	var skin: SkinConfig = Global.items_db.skins[selected_skin]
	($Base/Centering/Lobby/Player/Skin/Name as Label).text = skin.skin_name
	($Base/Centering/Lobby/Player/Skin/RarityFill as ColorRect).color = \
			ItemsDB.RARITY_COLORS[skin.rarity]
	($Base/Centering/Lobby/Player/Skin as TextureRect).texture = \
			load(skin.image_path) as Texture2D
	Global.set_int("selected_skin", selected_skin)


func _get_player_name() -> String:
	return ($Base/Centering/Main/Name/LineEdit as LineEdit).text.strip_edges().strip_escapes()


func _on_create_pressed() -> void:
	if _get_player_name().is_empty():
		create_error_dialog("Недопустимое имя!")
		return
	_status.text = "Создание сервера..."
	game_create_requested.emit()


func _on_join_pressed() -> void:
	if _get_player_name().is_empty():
		create_error_dialog("Недопустимое имя!")
		return
	_ip_dialog.popup_centered()
	_ip_edit.grab_focus()


func _on_leave_pressed() -> void:
	game_leave_requested.emit()


func _on_ip_dialog_confirmed() -> void:
	if _ip_edit.text.is_valid_ip_address():
		_status.text = "Подключение к %s..." % _ip_edit.text
		game_join_requested.emit(_ip_edit.text)
		_ip_dialog.hide()
	else:
		_ip_edit.placeholder_text = "Некорректный IP-адрес!"
		_ip_edit.text = ""


func _on_line_edit_text_changed(_new_text: String) -> void:
	_ip_edit.placeholder_text = "123.456.789.012"


func _on_connected_to_ip_pressed() -> void:
	DisplayServer.clipboard_set(_ip_edit.text)


func _on_game_created(error: int) -> void:
	_status.text = ""
	if error:
		create_error_dialog("Невозможно создать сервер!", error)
		return
	($Base/Centering/Lobby as Control).show()
	($Base/Centering/Main as Control).hide()
	($Base/Centering/Lobby/ControlButtons/ConnectedToIP as Control).hide()
	($Base/Centering/Lobby/ControlButtons/ViewIPs as Control).show()
	_players.clear()
	if not Global.HEADLESS:
		($ChatPanel as Chat).create_prefix_from_name(_get_player_name())
		Global.set_string("player_name", _get_player_name())
		_register_new_player(_get_player_name())


func _on_game_joined(error: int) -> void:
	_status.text = ""
	if error:
		create_error_dialog("Невозможно подключиться к серверу!", error)
		return
	($Base/Centering/Lobby/AdminPanel as HBoxContainer).hide()
	($Base/Centering/Lobby/ClientHint as Label).show()
	($Base/Centering/Lobby/ControlButtons/ConnectedToIP as Control).show()
	($Base/Centering/Lobby/ControlButtons/ConnectedToIP as LinkButton).text = "Подключён к %s" % _ip_edit.text
	($Base/Centering/Lobby/ControlButtons/ViewIPs as Control).hide()
	($Base/Centering/Lobby/ClientHint as Label).text = "Ожидание сервера... (возможно, игра уже началась)"
	($Base/Centering/Lobby as Control).show()
	($Base/Centering/Main as Control).hide()
	($ChatPanel as Chat).create_prefix_from_name(_get_player_name())
	Global.set_string("player_name", _get_player_name())
	_register_new_player.rpc_id(1, _get_player_name())


func _on_connection_closed() -> void:
	show()
	for i: Node in _players_container.get_children():
		i.queue_free()
	($ChatPanel as Chat).clear_chat()
	($Base/Centering/Lobby/ControlButtons/Chat as Button).toggled.emit(false)
	($Base/Centering/Lobby/ControlButtons/Chat as Button).button_pressed = false
	($Base/Centering/Lobby as Control).hide()
	($Base/Centering/Main as Control).show()


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	($ChatPanel as Chat).post_message.rpc("Игра: Игрок [color=green]%s[/color] отключился!" % _players[id])
	_players.erase(id)
	if id == _player_admin_id:
		if _players.size() > 0:
			_player_admin_id = (_players.keys() as Array[int])[0]
			_set_admin.rpc_id(_player_admin_id, true)
		else:
			_player_admin_id = -1
	_delete_player_entry.rpc(id)
	if not Global.HEADLESS:
		_delete_player_entry(id)


func _on_server_disconnected() -> void:
	create_error_dialog("Разорвано соединение с сервером!")


func _on_change_game_pressed() -> void:
	_item_selector.open_selection(ItemsDB.Item.GAME, selected_game)


func _on_change_map_pressed() -> void:
	_item_selector.open_selection(ItemsDB.Item.MAP, selected_map, selected_game)


func _on_change_skin_pressed() -> void:
	_item_selector.open_selection(ItemsDB.Item.SKIN, selected_skin)


func _on_change_light_weapon_pressed() -> void:
	_item_selector.open_selection(ItemsDB.Item.WEAPON_LIGHT, selected_light_weapon)


func _on_change_heavy_weapon_pressed() -> void:
	_item_selector.open_selection(ItemsDB.Item.WEAPON_HEAVY, selected_heavy_weapon)


func _on_change_support_weapon_pressed() -> void:
	_item_selector.open_selection(ItemsDB.Item.WEAPON_SUPPORT, selected_support_weapon)


func _on_change_melee_weapon_pressed() -> void:
	_item_selector.open_selection(ItemsDB.Item.WEAPON_MELEE, selected_melee_weapon)


func _on_start_game_pressed() -> void:
	if multiplayer.is_server():
		_request_start_game()
	else:
		_request_start_game.rpc_id(1)


func _on_item_selected(type: ItemsDB.Item, id: int) -> void:
	match type:
		ItemsDB.Item.GAME:
			if not multiplayer.is_server():
				_request_set_environment.rpc_id(1, id, 0)
			else:
				_request_set_environment(id, 0)
		ItemsDB.Item.MAP:
			if not multiplayer.is_server():
				_request_set_environment.rpc_id(1, selected_game, id)
			else:
				_request_set_environment(selected_game, id)
		ItemsDB.Item.SKIN:
			selected_skin = id
			_update_weapons_and_skin()
		ItemsDB.Item.WEAPON_LIGHT:
			selected_light_weapon = id
			_update_weapons_and_skin()
		ItemsDB.Item.WEAPON_HEAVY:
			selected_heavy_weapon = id
			_update_weapons_and_skin()
		ItemsDB.Item.WEAPON_SUPPORT:
			selected_support_weapon = id
			_update_weapons_and_skin()
		ItemsDB.Item.WEAPON_MELEE:
			selected_melee_weapon = id
			_update_weapons_and_skin()


func _on_game_started(success: bool) -> void:
	if not success:
		create_error_dialog("Ошибка загрузки игры!")
	else:
		hide()


func _on_game_ended() -> void:
	show()
