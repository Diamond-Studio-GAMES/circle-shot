extends Control


enum StartRejectReason {
	OK = 0,
	TOO_FEW_PLAYERS = 1,
	TOO_MANY_PLAYERS = 2,
	INDIVISIBLE_NUMBER_OF_PLAYERS = 3,
}

var _selected_event: int = 0
var _selected_map: int = 0
var _selected_skin: int = 0
var _selected_light_weapon: int = 0
var _selected_heavy_weapon: int = 0
var _selected_support_weapon: int = 0
var _selected_melee_weapon: int = 0
var _selected_skill: int = 0
var _players: Dictionary[int, String]
var _admin_id: int = -1
var _admin := false
var _local_game_id: int = 0
var _udp_peers: Array[PacketPeerUDP]
var _player_entry_scene: PackedScene = preload("uid://dj0mx5ui2wu4n")

@onready var _game: Game = get_parent()
@onready var _players_container: GridContainer = %PlayersContainer
@onready var _items_grid: ItemsGrid = %ItemsGrid
@onready var _item_selector: Window = $ItemSelector
@onready var _chat: Chat = $Panels/Chat
@onready var _countdown_timer: Timer = $CountdownTimer


func _ready() -> void:
	_game.created.connect(_on_game_created)
	_game.joined.connect(_on_game_joined)
	_game.closed.connect(_on_game_closed)
	_game.started.connect(_on_game_started)
	_game.ended.connect(_on_game_ended)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	hide()
	
	_selected_event = Globals.get_int("selected_event")
	_selected_map = Globals.get_int("selected_map")
	_selected_skin = Globals.get_int("selected_skin")
	_selected_light_weapon = Globals.get_int("selected_light_weapon")
	_selected_heavy_weapon = Globals.get_int("selected_heavy_weapon")
	_selected_support_weapon = Globals.get_int("selected_support_weapon")
	_selected_melee_weapon = Globals.get_int("selected_melee_weapon")
	_selected_skill = Globals.get_int("selected_skill")
	_update_equip()
	_update_environment()
	
	_find_ips_for_broadcast()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST \
				when multiplayer.has_multiplayer_peer() and not is_instance_valid(_game.event):
			_on_leave_pressed()


@rpc("reliable", "call_local")
func _add_player_entry(id: int, player_name: String) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	var player_entry: Node = _player_entry_scene.instantiate()
	player_entry.name = str(id)
	if id == multiplayer.get_unique_id():
		(player_entry.get_node(^"Name") as Label).add_theme_color_override(
				&"font_color", Color.CORNFLOWER_BLUE
		)
		(player_entry.get_node(^"Kick") as BaseButton).disabled = true
	(player_entry.get_node(^"Name") as Label).text = player_name
	(player_entry.get_node(^"Kick") as Control).visible = _admin
	(player_entry.get_node(^"Kick") as BaseButton).pressed.connect(_on_kick_pressed.bind(id))
	_players_container.add_child(player_entry)
	print_verbose("Added player %d entry with name: %s." % [id, player_name])


@rpc("reliable", "call_local")
func _delete_player_entry(id: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	_players_container.get_node(str(id)).queue_free()
	print_verbose("Deleted player %d entry." % id)


@rpc("any_peer", "reliable", "call_local")
func _register_new_player(player_name: String) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	
	if sender_id in _players:
		push_warning("Player %d is already registered!")
		return
	
	for i: int in _players:
		_add_player_entry.rpc_id(sender_id, i, _players[i])
	_set_environment.rpc_id(sender_id, _selected_event, _selected_map)
	
	player_name = Game.validate_player_name(player_name, sender_id)
	_players[sender_id] = player_name
	
	_chat.post_message.rpc("> [color=green]%s[/color] подключается!" % player_name)
	_chat.players_names[sender_id] = player_name
	
	if _players.size() == 1:
		_admin_id = sender_id
		_set_admin.rpc_id(sender_id, true)
	else:
		_set_admin.rpc_id(sender_id, false)
	
	_add_player_entry.rpc(sender_id, player_name)
	print_verbose("Registered player %d with name %s." % [sender_id, player_name])


@rpc("reliable", "call_local")
func _set_admin(admin: bool) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	(%AdminPanel as Control).visible = admin
	(%ClientHint as Control).visible = not admin
	for i: Node in _players_container.get_children():
		(i.get_node(^"Kick") as Control).visible = admin
	if admin:
		var my_event_id: int = Globals.get_int("selected_event")
		var my_map_id: int = Globals.get_int("selected_map")
		_request_set_environment.rpc_id(1, my_event_id, my_map_id)
	else:
		(%ClientHint as Label).text = "Начать игру может только хост."
	_admin = admin
	print_verbose("Admin set: %s." % str(admin))


@rpc("any_peer", "reliable", "call_local")
func _request_set_environment(event_id: int, map_id: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != _admin_id:
		push_warning("Set environment request rejected: player %d is not admin!" % sender_id)
		return
	
	if _game.state != Game.State.LOBBY:
		push_warning("Set environment request rejected: current game state is not lobby!")
		return
	if not _countdown_timer.is_stopped():
		push_warning("Set environment request rejected: counting down.")
		return
	
	if event_id < 0 or event_id >= Globals.items_db.events.size():
		push_warning("Rejected set environment request from %d. Incorrect event ID: %d." % [
			sender_id,
			event_id,
		])
		return
	if map_id < 0 or map_id >= Globals.items_db.events[event_id].maps.size():
		push_warning("Rejected set environment request from %d. Incorrect map ID: %d." % [
			sender_id,
			map_id,
		])
		return
	
	_game.max_players = Globals.items_db.events[event_id].max_players
	print_verbose("Accepted set environment request. Event ID: %d, Map ID: %d." % [
		event_id,
		map_id,
	])
	_set_environment.rpc(event_id, map_id)


@rpc("call_local", "reliable")
func _set_environment(event_id: int, map_id: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	_selected_event = event_id
	_selected_map = map_id
	print_verbose("Environment set: Event ID - %d, Map ID - %d." % [event_id, map_id])
	_update_environment()


@rpc("any_peer", "reliable", "call_local")
func _request_kick_player(id: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != _admin_id:
		push_warning("Kick request rejected: player %d is not admin!" % sender_id)
		return
	if id == _admin_id:
		push_warning("Cannot kick admin!")
		return
	if _game.state != Game.State.LOBBY:
		push_warning("Cannot kick if not in lobby!")
		return
	
	print_verbose("Accepted kick request. Kicking: %d." % id)
	(multiplayer as SceneMultiplayer).disconnect_peer(id)
	_chat.post_message.rpc("> [color=green]%s[/color] выгоняет игрока [color=red]%s[/color]!" % [
		_players[_admin_id],
		_players[id],
	])
	_chat.players_names.erase(id)
	_players.erase(id)
	_delete_player_entry.rpc(id)


@rpc("any_peer", "reliable", "call_local")
func _request_start_event() -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != _admin_id:
		push_warning("Start request rejected: player %d is not admin!" % sender_id)
		return
	
	if _game.state != Game.State.LOBBY:
		push_warning("Start request rejected: current state game is not lobby!")
		return
	if not _countdown_timer.is_stopped():
		push_warning("Start request rejected: counting down already!")
		return
	
	var start_reject_reason: StartRejectReason = _get_start_reject_reason()
	if start_reject_reason != StartRejectReason.OK:
		_reject_start_event.rpc_id(sender_id, start_reject_reason, _players.size())
		return
	
	print_verbose("Accepted start event request. Starting countdown...")
	_countdown_timer.start()
	_show_countdown.rpc()


@rpc("call_local", "reliable")
func _show_countdown() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	if _admin:
		(%AdminPanel as Control).hide()
	else:
		(%ClientHint as Control).hide()
	(%Countdown as Control).show()
	(%Countdown/AnimationPlayer as AnimationPlayer).play(&"Countdown")


@rpc("call_local", "reliable")
func _hide_countdown() -> void:
	if _admin:
		(%AdminPanel as Control).show()
	else:
		(%ClientHint as Control).show()
	(%Countdown as Control).hide()
	(%Countdown/AnimationPlayer as AnimationPlayer).stop()


@rpc("reliable", "call_local")
func _reject_start_event(reason: StartRejectReason, players_count: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	match reason:
		StartRejectReason.OK:
			push_warning("This method can't be called with OK reject reason!")
		StartRejectReason.TOO_FEW_PLAYERS:
			_game.show_error(
					"Невозможно начать игру: слишком мало игроков (%d) при минимуме в %d!" % [
						players_count,
						Globals.items_db.events[_selected_event].min_players,
					]
			)
			print_verbose("Start rejected: too few players (%d) with minimum %d." % [
				players_count,
				Globals.items_db.events[_selected_event].min_players,
			])
		StartRejectReason.TOO_MANY_PLAYERS:
			_game.show_error(
					"Невозможно начать игру: слишком много игроков (%d) при максимуме в %d!" % [
						players_count,
						Globals.items_db.events[_selected_event].max_players,
					]
			)
			print_verbose("Start rejected: too many players (%d) with maximum %d." % [
				players_count,
				Globals.items_db.events[_selected_event].max_players,
			])
		StartRejectReason.INDIVISIBLE_NUMBER_OF_PLAYERS:
			_game.show_error(
					"Невозможно начать игру: количество игроков (%d) не делится на %d!" % [
						players_count,
						Globals.items_db.events[_selected_event].players_divider,
					]
			)
			print_verbose("Start rejected: number of players (%d) doesn't divide on %d." % [
				players_count,
				Globals.items_db.events[_selected_event].players_divider,
			])
		_:
			push_warning("Received invalid reject reason!")


@rpc("call_local", "reliable")
func _start_event(event_id: int, map_id: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	_chat.clear_chat()
	if not ($UDPTimer as Timer).is_stopped():
		($UDPTimer as Timer).stop()
	if not ($UpdateIPSTimer as Timer).is_stopped():
		($UpdateIPSTimer as Timer).stop()
	if multiplayer.is_server():
		($ViewIPDialog as Window).hide()
		if Globals.headless:
			_game.load_event(event_id, map_id)
			return
	_item_selector.hide()
	
	_game.load_event(event_id, map_id, Globals.get_string("player_name"), [
		_selected_skin,
		_selected_light_weapon,
		_selected_heavy_weapon,
		_selected_support_weapon,
		_selected_melee_weapon,
		_selected_skill,
	])


func _update_environment() -> void:
	var event: EventData = Globals.items_db.events[_selected_event]
	(%Event as TextureRect).texture = load(event.image_path)
	(%Event/Container/Name as Label).text = event.name
	(%Event/Container/Description as Label).text = event.brief_description
	
	(%Map as TextureRect).texture = load(event.maps[_selected_map].image_path)
	(%Map/Container/Name as Label).text = event.maps[_selected_map].name
	(%Map/Container/Description as Label).text = event.maps[_selected_map].brief_description


func _update_equip() -> void:
	var skin: SkinData = Globals.items_db.skins[_selected_skin]
	(%Skin/Name as Label).text = skin.name
	(%Skin/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[skin.rarity]
	(%Skin as TextureRect).texture = load(skin.image_path)
	
	var light_weapon: WeaponData = Globals.items_db.weapons_light[_selected_light_weapon]
	(%LightWeapon/Name as Label).text = light_weapon.name
	(%LightWeapon/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[light_weapon.rarity]
	(%LightWeapon as TextureRect).texture = load(light_weapon.image_path)
	
	var heavy_weapon: WeaponData = Globals.items_db.weapons_heavy[_selected_heavy_weapon]
	(%HeavyWeapon/Name as Label).text = heavy_weapon.name
	(%HeavyWeapon/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[heavy_weapon.rarity]
	(%HeavyWeapon as TextureRect).texture = load(heavy_weapon.image_path)
	
	var support_weapon: WeaponData = Globals.items_db.weapons_support[_selected_support_weapon]
	(%SupportWeapon/Name as Label).text = support_weapon.name
	(%SupportWeapon/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[support_weapon.rarity]
	(%SupportWeapon as TextureRect).texture = load(support_weapon.image_path)
	
	var melee_weapon: WeaponData = Globals.items_db.weapons_melee[_selected_melee_weapon]
	(%MeleeWeapon/Name as Label).text = melee_weapon.name
	(%MeleeWeapon/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[melee_weapon.rarity]
	(%MeleeWeapon as TextureRect).texture = load(melee_weapon.image_path)
	
	var skill: SkillData = Globals.items_db.skills[_selected_skill]
	(%Skill/Name as Label).text = skill.name
	(%Skill/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[skill.rarity]
	(%Skill as TextureRect).texture = load(skill.image_path)


func _get_start_reject_reason() -> StartRejectReason:
	var start_reject_reason := StartRejectReason.OK
	if _players.size() < Globals.items_db.events[_selected_event].min_players:
		start_reject_reason = StartRejectReason.TOO_FEW_PLAYERS
		print_verbose("Rejecting start: too few players (%d), need %d." % [
			_players.size(),
			Globals.items_db.events[_selected_event].min_players,
		])
	elif _players.size() > Globals.items_db.events[_selected_event].max_players:
		start_reject_reason = StartRejectReason.TOO_MANY_PLAYERS
		print_verbose("Rejecting start: too many players (%d), max %d." % [
			_players.size(),
			Globals.items_db.events[_selected_event].max_players,
		])
	elif _players.size() % Globals.items_db.events[_selected_event].players_divider != 0:
		start_reject_reason = StartRejectReason.INDIVISIBLE_NUMBER_OF_PLAYERS
		print_verbose("Rejecting start: indivisible number of players (%d), must divide on %d." % [
			_players.size(),
			Globals.items_db.events[_selected_event].players_divider,
		])
	return start_reject_reason


func _find_ips_for_broadcast() -> void:
	_udp_peers.clear()
	print_verbose("Finding IPs for broadcast...")
	# Отсылаем пакеты по всем локальным адресам
	# TODO: Ждать PR где добавят возможность искать широковещательные адреса
	for i: String in IP.get_local_addresses():
		if i.begins_with("192.168.") or i.begins_with("10.42.") or i.begins_with("10.22."):
			var udp := PacketPeerUDP.new()
			udp.set_broadcast_enabled(true)
			# Меняем конец IP на 255
			var broadcast_ip: String = i.rsplit('.', true, 1)[0] + ".255"
			udp.set_dest_address(broadcast_ip, Game.LISTEN_PORT)
			print_verbose("Found IP to broadcast: %s" % broadcast_ip)
			_udp_peers.append(udp)


func _do_broadcast() -> void:
	var data := PackedByteArray()
	data.append(_local_game_id) # ID игры
	data.append(_players.size()) # Текущее количество игроков
	data.append(_game.max_players) # Максимальное количество игроков
	data.append_array(Globals.get_string("player_name", "Local Server").to_utf8_buffer()) # Имя
	for i: PacketPeerUDP in _udp_peers:
		i.put_packet(data)
	print_verbose("Broadcast of Game %d done. Data sent: %s (%d/%d)" % [
		_local_game_id,
		Globals.get_string("player_name", "Local Server"),
		_players.size(),
		_game.max_players,
	])


func _on_countdown_timer_timeout() -> void:
	print_verbose("Countdown ended.")	
	var start_reject_reason: StartRejectReason = _get_start_reject_reason()
	if start_reject_reason != StartRejectReason.OK:
		_hide_countdown.rpc()
		_reject_start_event.rpc_id(_admin_id, start_reject_reason, _players.size())
		return
	
	print_verbose("Countdown ended. Starting...")
	_start_event.rpc(_selected_event, _selected_map)


func _on_game_created() -> void:
	show()
	(%ControlButtons/ConnectedToIP as Control).hide()
	(%ControlButtons/ViewIPs as Control).show()
	_players.clear()
	($UDPTimer as Timer).start()
	($UpdateIPSTimer as Timer).start()
	_local_game_id = randi() % 256
	if not Globals.headless:
		_register_new_player.rpc_id(1, Globals.get_string("player_name"))
	_do_broadcast()


func _on_game_joined() -> void:
	show()
	(%AdminPanel as HBoxContainer).hide()
	(%ClientHint as Label).show()
	(%ControlButtons/ConnectedToIP as Control).show()
	(%ControlButtons/ConnectedToIP as LinkButton).text = "Подключёно к %s" % \
			(multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(1).get_remote_address()
	(%ControlButtons/ViewIPs as Control).hide()
	(%ClientHint as Label).text = "Ожидание сервера..."
	_register_new_player.rpc_id(1, Globals.get_string("player_name"))


func _on_game_closed() -> void:
	hide()
	_item_selector.hide()
	
	if not ($UDPTimer as Timer).is_stopped():
		($UDPTimer as Timer).stop()
	if not ($UpdateIPSTimer as Timer).is_stopped():
		($UpdateIPSTimer as Timer).stop()
	if not _countdown_timer.is_stopped():
		_countdown_timer.stop()
	_hide_countdown()
	
	for i: Node in _players_container.get_children():
		i.queue_free()
	
	_chat.clear_chat()
	(%ControlButtons/Chat as Button).button_pressed = false


func _on_game_started() -> void:
	_hide_countdown()
	hide()


func _on_game_ended() -> void:
	show()
	if multiplayer.is_server():
		($UDPTimer as Timer).start()
		($UpdateIPSTimer as Timer).start()


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	_chat.post_message.rpc("> [color=green]%s[/color] отключается!" % _players[id])
	_chat.players_names.erase(id)
	_players.erase(id)
	if id == _admin_id:
		if _players.size() > 0:
			_admin_id = (_players.keys() as Array[int])[0]
			_set_admin.rpc_id(_admin_id, true)
		else:
			_admin_id = -1
			_chat.clear_chat()
	_delete_player_entry.rpc(id)


func _on_kick_pressed(id: int) -> void:
	_request_kick_player.rpc_id(1, id)


func _on_start_event_pressed() -> void:
	_request_start_event.rpc_id(1)


func _on_leave_pressed() -> void:
	_game.close()


func _on_connected_to_ip_pressed() -> void:
	DisplayServer.clipboard_set(
			(multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(1).get_remote_address()
	)


func _on_change_event_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.EVENT, _selected_event)
	_item_selector.title = "Выбор события"
	_item_selector.popup_centered()


func _on_change_map_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.MAP, _selected_map, _selected_event)
	_item_selector.title = "Выбор карты"
	_item_selector.popup_centered()


func _on_change_skin_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.SKIN, _selected_skin)
	_item_selector.title = "Выбор скина"
	_item_selector.popup_centered()


func _on_change_light_weapon_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.WEAPON_LIGHT, _selected_light_weapon)
	_item_selector.title = "Выбор лёгкого оружия"
	_item_selector.popup_centered()


func _on_change_heavy_weapon_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.WEAPON_HEAVY, _selected_heavy_weapon)
	_item_selector.title = "Выбор тяжёлого оружия"
	_item_selector.popup_centered()


func _on_change_support_weapon_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.WEAPON_SUPPORT, _selected_support_weapon)
	_item_selector.title = "Выбор оружия поддержки"
	_item_selector.popup_centered()


func _on_change_melee_weapon_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.WEAPON_MELEE, _selected_melee_weapon)
	_item_selector.title = "Выбор ближнего оружия"
	_item_selector.popup_centered()


func _on_change_skill_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.SKILL, _selected_skill)
	_item_selector.title = "Выбор навыка"
	_item_selector.popup_centered()


func _on_item_selected(type: ItemsDB.Item, id: int) -> void:
	_item_selector.hide()
	match type:
		ItemsDB.Item.EVENT:
			if id != _selected_event:
				_request_set_environment.rpc_id(1, id, 0)
				Globals.set_int("selected_event", id)
				Globals.set_int("selected_map", 0)
		ItemsDB.Item.MAP:
			_request_set_environment.rpc_id(1, _selected_event, id)
			Globals.set_int("selected_map", id)
		ItemsDB.Item.SKIN:
			_selected_skin = id
			Globals.set_int("selected_skin", id)
			_update_equip()
		ItemsDB.Item.WEAPON_LIGHT:
			_selected_light_weapon = id
			Globals.set_int("selected_light_weapon", id)
			_update_equip()
		ItemsDB.Item.WEAPON_HEAVY:
			_selected_heavy_weapon = id
			Globals.set_int("selected_heavy_weapon", id)
			_update_equip()
		ItemsDB.Item.WEAPON_SUPPORT:
			_selected_support_weapon = id
			Globals.set_int("selected_support_weapon", id)
			_update_equip()
		ItemsDB.Item.WEAPON_MELEE:
			_selected_melee_weapon = id
			Globals.set_int("selected_melee_weapon", id)
			_update_equip()
		ItemsDB.Item.SKILL:
			_selected_skill = id
			Globals.set_int("selected_skill", id)
			_update_equip()
