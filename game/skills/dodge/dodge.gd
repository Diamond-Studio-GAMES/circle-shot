extends Skill


@export var roll_speed := 1280.0
@export var roll_duration := 0.5
@export var additional_invincibility := 0.1

var _roll_direction := Vector2.RIGHT
@onready var _aim_dodge: bool = Globals.get_setting_bool("aim_dodge")
@onready var _roll_timer: Timer = $Timer
@onready var _response_timer: Timer = $ResponseTimer


func _physics_process(delta: float) -> void:
	super(delta)
	if _player.is_local():
		if _aim_dodge:
			_roll_direction = _player.player_input.aim_direction
		elif not _player.entity_input.direction.is_zero_approx():
			_roll_direction = _player.entity_input.direction


func _use() -> void:
	if multiplayer.is_server():
		_response_timer.start()
	if not _player.is_local():
		return
	_request_dodge.rpc_id(1, _roll_direction)


@rpc("reliable", "call_local", "authority", 2)
func dodge(direction: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		push_error("This method must be called only by server!")
		return
	
	_player.make_disarmed()
	_player.make_immobile()
	_player.knockback = direction * roll_speed
	var previous_collision_layer: int = _player.collision_layer
	_player.collision_layer = 0
	
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_player.visual, ^"rotation", TAU * _player.visual.scale.x, roll_duration)
	tween.tween_callback(func() -> void: _player.visual.rotation = 0.0)
	
	_roll_timer.start(roll_duration)
	await _roll_timer.timeout
	
	_player.unmake_disarmed()
	_player.unmake_immobile()
	_player.knockback = Vector2.ZERO
	
	_roll_timer.start(additional_invincibility)
	await _roll_timer.timeout
	
	_player.collision_layer = previous_collision_layer


@rpc("reliable", "call_local", "any_peer", 2)
func _request_dodge(direction: Vector2) -> void:
	if not multiplayer.is_server():
		push_error("This method must be called only on server!")
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if _player.id != sender_id:
		push_warning("RPC Sender ID (%d) doesn't match with player ID (%d)!" % [
			sender_id, _player.id
		])
		return
	
	if _response_timer.is_stopped():
		push_warning("Dodge request from %d rejected: response timer is not running!" % [sender_id])
		return
	
	_response_timer.stop()
	dodge.rpc(direction.normalized())
