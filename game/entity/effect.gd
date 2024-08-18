class_name Effect
extends Node

const SPEED_CHANGE := "uid://dkyu57ilvneen"
@export var can_stack := true
var duration: float = 1.0
var data: Array
var entity: Entity


func _ready() -> void:
	($Timer as Timer).start(duration)
	_start_effect()


func _start_effect() -> void:
	pass


func _end_effect() -> void:
	pass


func _on_timer_timeout() -> void:
	_end_effect()
	queue_free()
