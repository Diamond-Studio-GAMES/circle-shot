class_name Effect
extends Node


const SPEED_CHANGE := "uid://dkyu57ilvneen"

@export var stackable := true
@export var negative := false
var timeless_counter: int = 0:
	set(value):
		timeless_counter = value
		if value <= 0 and _timer.is_stopped():
			clear()
var id: String
var _data: Array
var _entity: Entity
@onready var _timer: Timer = $Timer


func initialize(entity: Entity, data := [], timeless := false, duration := 1.0) -> void:
	id = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(scene_file_path))
	_entity = entity
	_data = data
	if timeless:
		timeless_counter += 1
	else:
		if duration <= 0.0:
			queue_free()
			return
		add_duration(duration)
	
	_start_effect()


func clear() -> void:
	_end_effect()
	queue_free()


func add_duration(time: float) -> void:
	_timer.start(_timer.time_left + time)


func _start_effect() -> void:
	pass


func _end_effect() -> void:
	pass


func _on_timer_timeout() -> void:
	if timeless_counter <= 0:
		clear()
