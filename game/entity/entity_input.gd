class_name EntityInput
extends MultiplayerSynchronizer


signal moving_started
signal moving_ended

var direction := Vector2():
	set(value):
		if not value.is_zero_approx():
			if direction.is_zero_approx():
				moving_started.emit()
		elif not direction.is_zero_approx():
			moving_ended.emit()
		direction = value
