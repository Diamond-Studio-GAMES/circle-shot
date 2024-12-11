# meta-name: Оружие
# meta-description: Содержит методы, переопределив которые можно создать новое оружия.
# meta-default: true
extends _BASE_


func _initialize() -> void:
_TS_pass


func _shoot() -> void:
_TS_pass


func _make_current() -> void:
_TS_pass


func _unmake_current() -> void:
_TS_pass


#func _can_reload() -> bool:
_TS_#return # Пиши дополнительные условия тут (или false если не должно перезаряжаться)


#func _can_use_additional_button() -> bool:
_TS_#return # Пиши условия тут


# Удали если оружие не должно перезаряжаться
func reload() -> void:
_TS_pass


#func additional_button() -> void:
_TS_#pass


#func has_additional_button() -> bool:
_TS_#return true


#func get_ammo_text() -> String:
_TS_#return # Составляй новый текст тут
