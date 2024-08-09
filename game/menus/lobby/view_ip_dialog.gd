extends AcceptDialog


const PREFFERED_IP_PREFIXES: Array[String] = [
	"192.168.",
	"10.42.",
]
const HIDE_IPS: Array[String] = [
	"127.0.0.1",
	"0:0:0:0:0:0:0:1",
]

var _global_ip_fetched := false
var _preffered_ips: Array[String]
var _other_ips: Array[String]
var _global_ip: String
@onready var _http_request: HTTPRequest = $HTTPRequest


func _ready() -> void:
	_find_ips()
	add_button("Обновить IP-адреса", false, "update_ips")
	add_button("Копировать IP-адреса", true, "copy_ips")


func _find_ips() -> void:
	_preffered_ips.clear()
	_other_ips.clear()
	_global_ip = ""
	_global_ip_fetched = false
	
	var ip_addresses: PackedStringArray = IP.get_local_addresses()
	for ip: String in ip_addresses:
		if ip in HIDE_IPS:
			continue
		var preffered := false
		for prefix: String in PREFFERED_IP_PREFIXES:
			if ip.begins_with(prefix):
				preffered = true
				break
		if preffered:
			_preffered_ips.append(ip)
		else:
			_other_ips.append(ip)
	
	dialog_text = ""
	if not _preffered_ips.is_empty():
		dialog_text += "Локальные IP-адреса: "
		var first := true
		for ip: String in _preffered_ips:
			if not first:
				dialog_text += ", "
			dialog_text += ip
			first = false
		dialog_text += '\n'
	if not _other_ips.is_empty():
		dialog_text += "Остальные локальные IP-адреса: "
		var first := true
		for ip: String in _other_ips:
			if not first:
				dialog_text += ", "
			dialog_text += ip
			first = false
	
	var error: Error = _http_request.request("https://icanhazip.com/")
	if error != OK:
		push_error("Can't connect to server! Error: %s" % error_string(error))
		dialog_text += '\n'
		dialog_text += "Невозможно создать запрос для получения глобального IP-адреса! \
Код ошибки: %d" % error


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _global_ip_fetched:
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Connect to server: result is not Success! Result: %d" % result)
		dialog_text += '\n'
		dialog_text += "Ошибка запроса глобального IP-адреса! Код ошибки: %d" % result
		return
	if response_code != HTTPClient.RESPONSE_OK:
		push_error("Connect to server: response code is not 200! Response code: %d" % response_code)
		dialog_text += '\n'
		dialog_text += "Ошибка получения глобального IP-адреса! Код ошибки: %d" % response_code
		return
	_global_ip = body.get_string_from_utf8().strip_escapes()
	dialog_text += '\n'
	dialog_text += "Глобальный IP-адрес: %s" % _global_ip
	dialog_text += '\n'
	dialog_text += "Чтобы игроки могли подключиться по глобальному IP-адресу, \
необходимо открыть порт: %d" % Game.PORT
	_global_ip_fetched = true


func _on_custom_action(action: StringName) -> void:
	match action:
		&"update_ips":
			_find_ips()
		&"copy_ips":
			var to_copy: String = ""
			if not _global_ip.is_empty():
				to_copy += _global_ip
				to_copy += '\n'
			if not _preffered_ips.is_empty():
				var first := true
				for ip: String in _preffered_ips:
					if not first:
						to_copy += ' '
					to_copy += ip
					first = false
				to_copy += '\n'
			if not _other_ips.is_empty():
				var first := true
				for ip: String in _other_ips:
					if not first:
						to_copy += ' '
					to_copy += ip
					first = false
			DisplayServer.clipboard_set(to_copy)
