class_name DuelUI
extends EventUI


func start_round(idx: int) -> void:
	($Main/RoundEnd as Label).text = ""
	(get_node("Main/Round%d" % idx) as CanvasItem).modulate = Color.WHITE


func end_round(idx: int, win_team: int, winner: int, end := false) -> void:
	var round_tex: TextureRect = get_node("Main/Round%d" % idx)
	round_tex.modulate = Entity.TEAM_COLORS[win_team]
	if end:
		if winner == multiplayer.get_unique_id():
			($Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"Victory")
			($Main/GameEnd as Label).text = "ПОБЕДА!"
		else:
			($Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"Defeat")
			($Main/GameEnd as Label).text = "ПОРАЖЕНИЕ!"
		return
	if winner == multiplayer.get_unique_id():
		($Main/RoundEnd as Label).text = "Раунд выигран!"
	else:
		($Main/RoundEnd as Label).text = "Раунд проигран!"
