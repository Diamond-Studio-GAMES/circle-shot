extends Game

var _spawn_points: Array[Node]
var _spawn_counter := 0 

func _make_teams() -> void:
	_spawn_points = $Map/SpawnPoints.get_children()
	_spawn_points.shuffle()
	var counter := 0
	for i: int in _players_data:
		_players_data[i].append(counter)
		counter += 1


func _get_spawn_point(_id: int) -> Vector2:
	var pos := (_spawn_points[_spawn_counter] as Node2D).global_position
	_spawn_counter += 1
	return pos
