extends Control


var _udp := UDPServer.new()
var _local_lobby_entry_scene: PackedScene = preload("uid://bs4vk7wdu27eo")
@onready var _game: Game = get_parent()
@onready var _ip_edit: LineEdit = %IPEdit
@onready var _lobbies_container: VBoxContainer = %LobbiesContainer
@onready var _no_lobbies_label: Label = %NoLobbiesLabel


func _ready() -> void:
	_game.created.connect(_on_game_created)
	_game.joined.connect(_on_game_joined)
	_game.closed.connect(_on_game_closed)
	
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		var clipboard_content: String = DisplayServer.clipboard_get().get_slice('\n', 0)
		if clipboard_content.is_valid_ip_address():
			_ip_edit.text = clipboard_content
	
	_udp.listen(Game.LISTEN_PORT)
	print_verbose("Started listening...")


func _process(_delta: float) -> void:
	if not _udp.is_listening():
		return
	
	_udp.poll()
	if _udp.is_connection_available():
		var peer: PacketPeerUDP = _udp.take_connection()
		var data: PackedByteArray = peer.get_packet()
		var id_nodepath := NodePath("Lobby%d" % data[0])
		var player_name: String = Game.validate_player_name(data.slice(3).get_string_from_utf8())
		var players: int = data[1]
		var max_players: int = data[2]
		print_verbose("Found lobby: %s (%d/%d) with ID %d from IP: %s" % [
			player_name,
			players,
			max_players,
			data[0],
			peer.get_packet_ip()
		])
		
		if _lobbies_container.has_node(id_nodepath):
			(_lobbies_container.get_node(id_nodepath).get_node(^"Timer") as Timer).start()
			(_lobbies_container.get_node(id_nodepath) as Button).text = "%s (%d/%d)" % [
				player_name,
				players,
				max_players
			]
			print_verbose("Lobby %d already in list. Updating timer." % data[0])
		else:
			var local_lobby_entry: Button = _local_lobby_entry_scene.instantiate()
			local_lobby_entry.name = id_nodepath.get_concatenated_names() # Конвертация в StringName
			local_lobby_entry.text = "%s (%d/%d)" % [player_name, players, max_players]
			local_lobby_entry.pressed.connect(_game.join.bind(peer.get_packet_ip()))
			_lobbies_container.add_child(local_lobby_entry)
			print_verbose("Lobby %d added to the list." % data[0])
	
	_no_lobbies_label.visible = _lobbies_container.get_child_count() == 0


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when not multiplayer.has_multiplayer_peer():
			_on_exit_pressed()


func _on_create_pressed() -> void:
	_game.create()


func _on_join_pressed() -> void:
	_game.join(_ip_edit.text)


func _on_exit_pressed() -> void:
	Globals.main.open_menu()


func _on_game_created() -> void:
	hide()
	_udp.stop()
	print_verbose("Listening stopped.")


func _on_game_joined() -> void:
	hide()
	_udp.stop()
	print_verbose("Listening stopped.")


func _on_game_closed() -> void:
	show()
	_udp.listen(Game.LISTEN_PORT)
	print_verbose("Listening restarted...")
