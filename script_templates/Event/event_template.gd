# meta-name: Событие
# meta-description: Содержит методы, переопределив которые можно создать новое событие.
# meta-default: true
class_name <NEWEVENTNAME>
extends _BASE_

@onready var _<neweventname>_ui: <NEWEVENTNAME>UI = $UI

func _initialize() -> void:
_TS_pass


func _make_teams() -> void:
_TS_pass


func _finish_setup() -> void:
_TS_pass


func _finish_start() -> void:
_TS_pass


#func _get_player_scene(_id: int) -> PackedScene:
_TS_#return player_scenes[0]


func _get_spawn_point(_id: int) -> Vector2:
_TS_return 


#func _customize_player(_player: Player) -> void:
_TS_#pass


#func _player_killed(_who: int, _by: int) -> void:
_TS_#pass


#func _player_disconnected(_id: int) -> void:
_TS_#pass
