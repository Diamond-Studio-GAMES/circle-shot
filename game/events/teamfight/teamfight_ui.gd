class_name TeamfightUI
extends EventUI


@rpc("reliable", "call_local")
func set_kills(red: int, blue: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	($Main/RedCount as Label).text = str(red)
	($Main/BlueCount as Label).text = str(blue)


@rpc("reliable", "call_local")
func show_winner(team_won: int) -> void:
	if team_won < 0:
		($Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"Draw")
		return
	($Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"Victory")
	($Main/GameEnd/Team as Label).text = "Красная" if team_won == 0 else "Синяя"
	($Main/GameEnd/Team as Control).add_theme_color_override(
			&"font_color", Entity.TEAM_COLORS[team_won]
	)


func set_time(time: int) -> void:
	($Main/Timer as Label).text = "%d:%02d" % [floori(time / 60.0), time % 60]


func show_comeback(time: int) -> void:
	var comeback: Label = $Main/Comeback
	comeback.show()
	
	var countdown: int = time
	while countdown > 0:
		comeback.text = "Возвращение через %d..." % countdown
		await get_tree().create_timer(1.0, false).timeout
		countdown -= 1
	
	comeback.hide()
