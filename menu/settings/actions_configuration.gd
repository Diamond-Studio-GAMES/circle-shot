extends Window


var _key_events: Dictionary[StringName, int]
var _mouse_button_events: Dictionary[StringName, int]

var _waiting_for_input := false
var _editing_action: StringName
var _coded_event_candidate_type: Main.ActionEventType
var _coded_event_candidate_value: int
var _pending_coded_event_types: Dictionary[StringName, Main.ActionEventType]
var _pending_coded_event_values: Dictionary[StringName, int]


func _ready() -> void:
	if not OS.has_feature("pc"):
		(%Actions/Fullscreen as Control).hide()
	($EventSelector as AcceptDialog).get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_load_keys_from_map()


func edit_action(action: StringName) -> void:
	_editing_action = action
	_waiting_for_input = true
	($EventSelector as AcceptDialog).get_ok_button().hide()
	($EventSelector as ConfirmationDialog).get_cancel_button().hide()
	($EventSelector as Window).title = 'Редактирование действия "%s"...' % \
			(%Actions.get_node(NodePath(action.to_pascal_case())).get_node(^"Name") as Label).text
	($EventSelector as AcceptDialog).dialog_text = "Ожидание ввода..."
	($EventSelector as Window).popup_centered()


func _load_keys_from_map() -> void:
	_key_events.clear()
	_mouse_button_events.clear()
	
	for i: StringName in InputMap.get_actions():
		if i.begins_with("ui_"):
			continue
		var event: InputEvent = InputMap.action_get_events(i)[0]
		(%Actions.get_node(NodePath(i.to_pascal_case())).get_node(^"Event") as Label).text = \
				_event_as_text(event)
		
		var mb := event as InputEventMouseButton
		if mb:
			_mouse_button_events[i] = mb.button_index
		var key := event as InputEventKey
		if key:
			_key_events[i] = key.physical_keycode


func _set_coded_event_candidate(type: Main.ActionEventType, value: int) -> void:
	_waiting_for_input = false
	_coded_event_candidate_type = type
	_coded_event_candidate_value = value
	($EventSelector as AcceptDialog).dialog_text = _coded_event_as_text(type, value)
	($EventSelector as AcceptDialog).get_ok_button().show()
	($EventSelector as ConfirmationDialog).get_cancel_button().show()


func _coded_event_as_text(type: Main.ActionEventType, value: int) -> String:
	match type:
		Main.ActionEventType.KEY:
			return OS.get_keycode_string(
					DisplayServer.keyboard_get_keycode_from_physical(value)
			)
		Main.ActionEventType.MOUSE_BUTTON:
			match value:
				MOUSE_BUTTON_LEFT:
					return "ЛКМ"
				MOUSE_BUTTON_MIDDLE:
					return "СКМ"
				MOUSE_BUTTON_RIGHT:
					return "ПКМ"
				MOUSE_BUTTON_XBUTTON1:
					return "X1"
				MOUSE_BUTTON_XBUTTON2:
					return "X2"
	return "НЕИЗВЕСТНО"


func _event_as_text(event: InputEvent) -> String:
	var mb := event as InputEventMouseButton
	if mb:
		return _coded_event_as_text(Main.ActionEventType.MOUSE_BUTTON, mb.button_index)
	
	var key := event as InputEventKey
	if key:
		return _coded_event_as_text(Main.ActionEventType.KEY, key.physical_keycode)
	
	return "НЕИЗВЕСТНО"


func _on_event_selector_window_input(event: InputEvent) -> void:
	if not _waiting_for_input:
		return
	
	var mb := event as InputEventMouseButton
	if mb:
		($EventSelector as Window).set_input_as_handled()
		if _mouse_button_events.get(_editing_action, -1) == mb.button_index:
			($EventSelector as AcceptDialog).dialog_text = "Введено текущее событие."
			return
		if mb.button_index in _mouse_button_events.values():
			($EventSelector as AcceptDialog).dialog_text = "Эта кнопка уже занята другим действием."
			return
		if mb.button_index in [
			MOUSE_BUTTON_LEFT,
			MOUSE_BUTTON_RIGHT,
			MOUSE_BUTTON_MIDDLE,
			MOUSE_BUTTON_XBUTTON1,
			MOUSE_BUTTON_XBUTTON2,
		]:
			_set_coded_event_candidate(Main.ActionEventType.MOUSE_BUTTON, mb.button_index)
	
	var key := event as InputEventKey
	if key:
		($EventSelector as Window).set_input_as_handled()
		if _key_events.get(_editing_action, -1) == key.physical_keycode:
			($EventSelector as AcceptDialog).dialog_text = "Введено текущее событие."
			return
		if key.physical_keycode in _key_events.values():
			($EventSelector as AcceptDialog).dialog_text = "Эта кнопка уже занята другим действием."
			return
		_set_coded_event_candidate(Main.ActionEventType.KEY, key.physical_keycode)


func _on_save_pressed() -> void:
	for i: StringName in _pending_coded_event_types:
		Globals.set_controls_int("action_%s_event_type" % i, _pending_coded_event_types[i])
		Globals.set_controls_int("action_%s_event_value" % i, _pending_coded_event_values[i])
	Globals.main.apply_controls_settings()
	_pending_coded_event_types.clear()
	_pending_coded_event_values.clear()
	_load_keys_from_map()
	($VBoxContainer/Buttons/Save as Button).disabled = true
	($VBoxContainer/Buttons/Discard as Button).disabled = true


func _on_discard_pressed() -> void:
	_pending_coded_event_types.clear()
	_pending_coded_event_values.clear()
	_load_keys_from_map()
	($VBoxContainer/Buttons/Discard as Button).disabled = true
	($VBoxContainer/Buttons/Discard as Button).disabled = true


func _on_event_selector_confirmed() -> void:
	_key_events.erase(_editing_action)
	_mouse_button_events.erase(_editing_action)
	match _coded_event_candidate_type:
		Main.ActionEventType.KEY:
			_key_events[_editing_action] = _coded_event_candidate_value
		Main.ActionEventType.MOUSE_BUTTON:
			_mouse_button_events[_editing_action] = _coded_event_candidate_value
	var np := NodePath(_editing_action.to_pascal_case())
	(%Actions.get_node(np).get_node(^"Event") as Label).text = \
			_coded_event_as_text(_coded_event_candidate_type, _coded_event_candidate_value)
	
	_pending_coded_event_types[_editing_action] = _coded_event_candidate_type
	_pending_coded_event_values[_editing_action] = _coded_event_candidate_value
	($VBoxContainer/Buttons/Save as Button).disabled = false
	($VBoxContainer/Buttons/Discard as Button).disabled = false


func _on_event_selector_canceled() -> void:
	_editing_action = &""
	_waiting_for_input = false
