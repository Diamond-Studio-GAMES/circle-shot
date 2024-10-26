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


# Удали если оружие не должно перезаряжаться
func reload() -> void:
_TS_pass


# Замени на return false если оружие не должно перезаряжаться
func can_reload() -> bool:
_TS_return super() # Добавляй условия тут


# Удали если оружие не имеет дополнительную кнопку
func additional_button() -> void:
_TS_pass


# Раскомментируй если оружие имеет дополнительную кнопку
#func has_additional_button() -> bool:
_TS_#return true


# Расскоментируй чтобы изменить текст о боеприпасах
#func get_ammo_text() -> String:
_TS_#return