extends Label

var _response_received := false
var _sent_ticks_msec: int
@onready var _timer: Timer = $PingTimer

@rpc("any_peer", "unreliable")
func _process_ping() -> void:
	_ping_response.rpc_id(multiplayer.get_remote_sender_id())


@rpc
func _ping_response() -> void:
	_response_received = true
	var ping_msec: int = Time.get_ticks_msec() - _sent_ticks_msec
	text = "Пинг: %d мс" % ping_msec


func _do_ping() -> void:
	_response_received = false
	_sent_ticks_msec = Time.get_ticks_msec()
	_process_ping.rpc_id(1)


func _on_game_joined(error: int) -> void:
	if error == OK:
		_response_received = true
		_timer.start()
		text = ""
		show()


func _on_connection_closed() -> void:
	_timer.stop()
	hide()


func _on_ping_timer_timeout() -> void:
	if _response_received:
		_do_ping()
	else:
		text = "Пинг: >999 мс"
