class_name PlayerInput
extends EntityInput

## Узел с вводом для игрока.

## Направление прицеливания.
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
		elif value.length_squared() > 1.0:
			aim_direction = value.limit_length(1.0)
		else:
			aim_direction = value
## Ведётся ли стрельба.
var shooting := false

## Показывается ли линия прицела.
var showing_aim := false
## Если равно [code]true[/code], то игрок поворачивается в направлении прицеливания,
## иначе направление прицела поворачивается в сторону движения игрока (если движется).
var turn_with_aim := true
