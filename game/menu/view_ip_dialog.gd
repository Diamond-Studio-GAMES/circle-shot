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
@onready var _http_request: HTTPRequest = $HTTPRequest


func _ready() -> void:
	_find_ips()
	add_button("Обновить IP-адреса", true, "update_ips")


func _find_ips() -> void:
	var ip_addresses: PackedStringArray = IP.get_local_addresses()
	var preffered_ips: Array[String]
	var other_ips: Array[String]
	for ip: String in ip_addresses:
		if ip in HIDE_IPS:
			continue
		var preffered := false
		for prefix: String in PREFFERED_IP_PREFIXES:
			if ip.begins_with(prefix):
				preffered = true
				break
		if preffered:
			preffered_ips.append(ip)
		else:
			other_ips.append(ip)
	
	dialog_text = ""
	if not preffered_ips.is_empty():
		dialog_text += "Локальные IP-адреса: "
		var first := true
		for ip: String in preffered_ips:
			if not first:
				dialog_text += ", "
			dialog_text += ip
			first = false
		dialog_text += '\n'
	if not other_ips.is_empty():
		dialog_text += "Остальные локальные IP-адреса: "
		var first := true
		for ip: String in other_ips:
			if not first:
				dialog_text += ", "
			dialog_text += ip
			first = false
	
	_global_ip_fetched = false
	var error: int = _http_request.request("https://icanhazip.com/")
	if error != 0:
		# Ошибку печатать
		dialog_text += '\n'
		dialog_text += "Невозможно создать запрос для получения глобального IP-адреса! Код ошибки: %d" % error


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _global_ip_fetched:
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		# Ошибку печатать
		dialog_text += '\n'
		dialog_text += "Ошибка запроса глобального IP-адреса! Код ошибки: %d" % result
		return
	if response_code != HTTPClient.RESPONSE_OK:
		# Ошибку печатать
		dialog_text += '\n'
		dialog_text += "Ошибка получения глобального IP-адреса! Код ошибки: %d" % response_code
		return
	dialog_text += '\n'
	dialog_text += "Глобальный IP-адрес: %s" % body.get_string_from_utf8()
	_global_ip_fetched = true


func _on_custom_action(action: StringName) -> void:
	if action == &"update_ips":
		_find_ips()
