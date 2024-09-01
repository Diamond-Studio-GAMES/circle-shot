class_name PlayerInput
extends EntityInput


signal aiming_started
signal aiming_ended
signal shooting_started
signal shooting_ended

var aim_direction := Vector2.RIGHT:
	get:
		if aiming:
			return aim_direction
		elif not is_zero_approx(direction.x):
			aim_direction.x = absf(aim_direction.x) * signf(direction.x)
		return aim_direction
var shooting := false:
	set(value):
		if value:
			if not shooting:
				shooting_started.emit()
		elif shooting:
			shooting_ended.emit()
		shooting = value
var aiming := false:
	set(value):
		if value:
			if not aiming:
				aiming_started.emit()
		elif aiming:
			aiming_ended.emit()
		aiming = value
