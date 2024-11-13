class_name PlayerInput
extends EntityInput


var aim_direction := Vector2.RIGHT:
	get:
		if not is_multiplayer_authority() or turn_with_aim:
			return aim_direction
		if not is_zero_approx(direction.x):
			aim_direction.x = absf(aim_direction.x) * signf(direction.x)
		return aim_direction
	set(value):
		if not value.is_finite() or value.is_zero_approx():
			aim_direction = Vector2.RIGHT
		else:
			aim_direction = value
var shooting := false

var showing_aim := false
var turn_with_aim := true
