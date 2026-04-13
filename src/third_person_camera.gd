extends Node3D

@export var mouse_sensitivity := 0.0022
@export var stick_sensitivity := 2.2
@export var pitch_min := deg_to_rad(-55.0)
@export var pitch_max := deg_to_rad(58.0)
## Eye offset from the player's origin along [CharacterBody3D.up_direction].
@export var eye_height := 1.55

@onready var _pitch_pivot: Node3D = $PitchPivot
@onready var _player: CharacterBody3D = get_parent() as CharacterBody3D

var _yaw: float = 0.0
var _pitch: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_yaw = rotation.y
	_pitch = _pitch_pivot.rotation.x
	_pitch_pivot.rotation = Vector3.ZERO
	_rebuild_rig_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, pitch_min, pitch_max)


func _process(_delta: float) -> void:
	var look_x := Input.get_axis(&"look_left", &"look_right")
	var look_y := Input.get_axis(&"look_up", &"look_down")
	if absf(look_x) > 0.01 or absf(look_y) > 0.01:
		_yaw -= look_x * stick_sensitivity * _delta
		_pitch = clampf(_pitch - look_y * stick_sensitivity * _delta, pitch_min, pitch_max)
	_rebuild_rig_transform()


func _rebuild_rig_transform() -> void:
	if _player == null:
		return
	var up: Vector3 = _player.get_effective_up_direction()
	if up.length_squared() < 0.0001:
		up = Vector3.UP
	else:
		up = up.normalized()

	global_position = _player.global_position + up * eye_height

	var ref_h := Vector3.FORWARD.slide(up)
	if ref_h.length_squared() < 0.0001:
		ref_h = Vector3.RIGHT.slide(up)
	if ref_h.length_squared() < 0.0001:
		ref_h = Vector3(0.0, 0.0, -1.0)
	ref_h = ref_h.normalized()

	var forward_h := ref_h.rotated(up, _yaw).normalized()
	var right := up.cross(forward_h).normalized()
	forward_h = right.cross(up).normalized()

	global_transform.basis = Basis.looking_at(forward_h, up, true).orthonormalized()
	_pitch_pivot.rotation = Vector3(_pitch, 0.0, 0.0)
