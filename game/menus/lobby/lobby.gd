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
var _players := {}
var _admin_id: int = -1
var _game_id: int = 0
var _udp_peers: Array[PacketPeerUDP]
var _player_entry_scene: PackedScene = preload("uid://dj0mx5ui2wu4n")

@onready var _game: Game = get_parent()
@onready var _players_container: GridContainer = %PlayersContainer
@onready var _items_grid: ItemsGrid = %ItemsGrid
@onready var _item_selector: Window = $ItemSelector
@onready var _chat: Chat = $Panels/Chat


func _ready() -> void:
	_game.created.connect(_on_game_created)
	_game.joined.connect(_on_game_joined)
	_game.closed.connect(_on_game_closed)
	_game.started.connect(_on_game_started)
	_game.ended.connect(_on_game_ended)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	hide()
	
	_selected_skin = Globals.get_int("selected_skin")
	_selected_light_weapon = Globals.get_int("selected_light_weapon")
	_selected_heavy_weapon = Globals.get_int("selected_heavy_weapon")
	_selected_support_weapon = Globals.get_int("selected_support_weapon")
	_selected_melee_weapon = Globals.get_int("selected_melee_weapon")
	_selected_skill = Globals.get_int("selected_skill")
	_update_equip()
	_update_environment()
	
	_find_ips_for_broadcast()


@rpc("reliable", "call_local")
func _add_player_entry(id: int, player_name: String) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	var player_entry: Node = _player_entry_scene.instantiate()
	player_entry.name = str(id)
	if id == multiplayer.get_unique_id():
		player_name += " (Ты)"
		(player_entry.get_node(^"Kick") as BaseButton).disabled = true
	(player_entry.get_node(^"Name") as Label).text = player_name
	# Проверка на админа своеобразная
	(player_entry.get_node(^"Kick") as Control).visible = %AdminPanel.visible
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


@rpc("any_peer", "reliable")
func _register_new_player(player_name: String) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	
	var id: int = multiplayer.get_remote_sender_id()
	if id == 0:
		id = 1 # Локально от сервера
	for i: int in _players:
		_add_player_entry.rpc_id(id, i, _players[i])
	_set_environment.rpc_id(id, _selected_event, _selected_map)
	_players[id] = player_name
	_chat.post_message.rpc("Игра: Игрок [color=green]%s[/color] подключился!" % player_name)
	_chat.players_names[id] = player_name
	if _players.size() == 1:
		_admin_id = id
		if id == 1:
			_set_admin(true)
		else:
			_set_admin.rpc_id(id, true)
	else:
		_set_admin.rpc_id(id, false)
	_add_player_entry.rpc(id, player_name)
	print_verbose("Registered player %d with name %s." % [id, player_name])


@rpc("reliable")
func _set_admin(admin: bool) -> void:
	if multiplayer.get_remote_sender_id() != 1 and not multiplayer.is_server():
		push_error("This method must be called only by server!")
		return
	
	(%AdminPanel as HBoxContainer).visible = admin
	(%ClientHint as Label).visible = not admin
	for i: Node in _players_container.get_children():
		i.get_node(^"Kick").visible = admin
	if admin:
		# Странный код
		_request_set_environment(Globals.get_int("selected_event"), Globals.get_int("selected_map"))
	else:
		(%ClientHint as Label).text = "Начать игру может только хост."
	print_verbose("Admin set: %s." % str(admin))


@rpc("any_peer", "reliable")
func _request_set_environment(event_id: int, map_id: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if sender_id != _admin_id:
		push_warning("Request rejected: player %d is not admin!" % sender_id)
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


@rpc("any_peer", "reliable")
func _request_kick_player(id: int) -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if sender_id != _admin_id:
		push_warning("Request rejected: player %d is not admin!" % sender_id)
		return
	print_verbose("Accepted kick request. Kicking: %d." % id)
	multiplayer.multiplayer_peer.disconnect_peer(id)


@rpc("any_peer", "reliable")
func _request_start_event() -> void:
	if not multiplayer.is_server():
		push_error("Unexpected call on client!")
		return
	var id: int = multiplayer.get_remote_sender_id()
	if id == 0:
		id = 1
	if id != _admin_id:
		push_warning("Request rejected: player %d is not admin!" % id)
		return
	
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
	if start_reject_reason != StartRejectReason.OK:
		if id == 1:
			_reject_start_event(start_reject_reason, _players.size())
		else:
			_reject_start_event.rpc_id(id, start_reject_reason, _players.size())
		return
	
	print_verbose("Accepted start event request. Starting...")
	_start_event.rpc(_selected_event, _selected_map)


@rpc("reliable")
func _reject_start_event(reason: StartRejectReason, players_count: int) -> void:
	if multiplayer.get_remote_sender_id() != 1 and not multiplayer.is_server():
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
					"Невозможно начать игру: количество игрков (%d) не делится на %d!" % [
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
	
	if not ($UDPTimer as Timer).is_stopped():
		($UDPTimer as Timer).stop()
	if not ($UpdateIPSTimer as Timer).is_stopped():
		($UpdateIPSTimer as Timer).stop()
	if multiplayer.is_server() and Globals.headless:
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
	Globals.set_int("selected_event", _selected_event)
	
	(%Map as TextureRect).texture = load(event.maps[_selected_map].image_path)
	(%Map/Container/Name as Label).text = event.maps[_selected_map].name
	(%Map/Container/Description as Label).text = event.maps[_selected_map].brief_description
	Globals.set_int("selected_map", _selected_map)


func _update_equip() -> void:
	var skin: SkinData = Globals.items_db.skins[_selected_skin]
	(%Skin/Name as Label).text = skin.name
	(%Skin/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[skin.rarity]
	(%Skin as TextureRect).texture = load(skin.image_path)
	Globals.set_int("selected_skin", _selected_skin)
	
	var light_weapon: WeaponData = Globals.items_db.weapons_light[_selected_light_weapon]
	(%LightWeapon/Name as Label).text = light_weapon.name
	(%LightWeapon/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[light_weapon.rarity]
	(%LightWeapon as TextureRect).texture = load(light_weapon.image_path)
	Globals.set_int("selected_light_weapon", _selected_light_weapon)
	
	var heavy_weapon: WeaponData = Globals.items_db.weapons_heavy[_selected_heavy_weapon]
	(%HeavyWeapon/Name as Label).text = heavy_weapon.name
	(%HeavyWeapon/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[heavy_weapon.rarity]
	(%HeavyWeapon as TextureRect).texture = load(heavy_weapon.image_path)
	Globals.set_int("selected_heavy_weapon", _selected_heavy_weapon)
	
	var support_weapon: WeaponData = Globals.items_db.weapons_support[_selected_support_weapon]
	(%SupportWeapon/Name as Label).text = support_weapon.name
	(%SupportWeapon/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[support_weapon.rarity]
	(%SupportWeapon as TextureRect).texture = load(support_weapon.image_path)
	Globals.set_int("selected_support_weapon", _selected_support_weapon)
	
	var melee_weapon: WeaponData = Globals.items_db.weapons_melee[_selected_melee_weapon]
	(%MeleeWeapon/Name as Label).text = melee_weapon.name
	(%MeleeWeapon/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[melee_weapon.rarity]
	(%MeleeWeapon as TextureRect).texture = load(melee_weapon.image_path)
	Globals.set_int("selected_melee_weapon", _selected_melee_weapon)
	
	var skill: SkillData = Globals.items_db.skills[_selected_skill]
	(%Skill/Name as Label).text = skill.name
	(%Skill/RarityFill as ColorRect).color = ItemsDB.RARITY_COLORS[skill.rarity]
	(%Skill as TextureRect).texture = load(skill.image_path)
	Globals.set_int("selected_skill", _selected_skill)


func _find_ips_for_broadcast() -> void:
	_udp_peers.clear()
	print_verbose("Finding IPs for broadcast...")
	# Отсылаем пакеты по всем локальным адресам
	for i: String in IP.get_local_addresses():
		if i.begins_with("192.168.") or i.begins_with("10.42."):
			var udp := PacketPeerUDP.new()
			udp.set_broadcast_enabled(true)
			# Меняем конец IP на 255
			var broadcast_ip: String = i.rsplit('.', true, 1)[0] + ".255"
			udp.set_dest_address(broadcast_ip, Game.LISTEN_PORT)
			print_verbose("Found IP to broadcast: %s" % broadcast_ip)
			_udp_peers.append(udp)


func _do_broadcast() -> void:
	var data := PackedByteArray()
	data.append(_game_id) # ID игры
	data.append(_players.size()) # Текущее количество игроков
	data.append(_game.max_players) # Максимальное количество игроков
	data.append_array(Globals.get_string("player_name", "Local Server").to_utf8_buffer()) # Имя хоста
	for i: PacketPeerUDP in _udp_peers:
		i.put_packet(data)
	print_verbose("Broadcast of Game %d done. Data sent: %s (%d/%d)" % [
		_game_id,
		Globals.get_string("player_name", "Local Server"),
		_players.size(),
		_game.max_players,
	])


func _on_game_created() -> void:
	show()
	(%ControlButtons/ConnectedToIP as Control).hide()
	(%ControlButtons/ViewIPs as Control).show()
	_players.clear()
	($UDPTimer as Timer).start()
	($UpdateIPSTimer as Timer).start()
	_game_id = randi() % 256
	if not Globals.headless:
		_register_new_player(Globals.get_string("player_name"))
	_do_broadcast()


func _on_game_joined() -> void:
	show()
	(%AdminPanel as HBoxContainer).hide()
	(%ClientHint as Label).show()
	(%ControlButtons/ConnectedToIP as Control).show()
	var peers: Array[ENetPacketPeer] = \
			(multiplayer.multiplayer_peer as ENetMultiplayerPeer).host.get_peers()
	(%ControlButtons/ConnectedToIP as LinkButton).text = "Подключён к %s" % \
			peers[0].get_remote_address()
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
	for i: Node in _players_container.get_children():
		i.queue_free()
	_chat.clear_chat()
	(%ControlButtons/Chat as Button).button_pressed = false


func _on_game_started() -> void:
	hide()


func _on_game_ended() -> void:
	show()
	if multiplayer.is_server():
		($UDPTimer as Timer).start()
		($UpdateIPSTimer as Timer).start()


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	_chat.post_message.rpc("Игра: Игрок [color=green]%s[/color] отключился!" % _players[id])
	_chat.players_names.erase(id)
	_players.erase(id)
	if id == _admin_id:
		if _players.size() > 0:
			_admin_id = (_players.keys() as Array[int])[0]
			_set_admin.rpc_id(_admin_id, true)
		else:
			_admin_id = -1
	_delete_player_entry.rpc(id)


func _on_kick_pressed(id: int) -> void:
	if multiplayer.is_server():
		_request_kick_player(id)
	else:
		_request_kick_player.rpc_id(1, id)


func _on_start_event_pressed() -> void:
	if multiplayer.is_server():
		_request_start_event()
	else:
		_request_start_event.rpc_id(1)


func _on_leave_pressed() -> void:
	_game.close()


func _on_connected_to_ip_pressed() -> void:
	var peers: Array[ENetPacketPeer] = \
			(multiplayer.multiplayer_peer as ENetMultiplayerPeer).host.get_peers()
	DisplayServer.clipboard_set(peers[0].get_remote_address())


func _on_change_event_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.EVENT, _selected_event)
	_item_selector.title = "Выбор события"
	_item_selector.popup_centered()


func _on_change_map_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.MAP, _selected_map)
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
			if not multiplayer.is_server():
				_request_set_environment.rpc_id(1, id, 0)
			else:
				_request_set_environment(id, 0)
		ItemsDB.Item.MAP:
			if not multiplayer.is_server():
				_request_set_environment.rpc_id(1, _selected_event, id)
			else:
				_request_set_environment(_selected_event, id)
		ItemsDB.Item.SKIN:
			_selected_skin = id
			_update_equip()
		ItemsDB.Item.WEAPON_LIGHT:
			_selected_light_weapon = id
			_update_equip()
		ItemsDB.Item.WEAPON_HEAVY:
			_selected_heavy_weapon = id
			_update_equip()
		ItemsDB.Item.WEAPON_SUPPORT:
			_selected_support_weapon = id
			_update_equip()
		ItemsDB.Item.WEAPON_MELEE:
			_selected_melee_weapon = id
			_update_equip()
