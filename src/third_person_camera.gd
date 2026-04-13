extends Node3D

@export var mouse_sensitivity := 0.0022
@export var stick_sensitivity := 2.2
@export var pitch_min := deg_to_rad(-55.0)
@export var pitch_max := deg_to_rad(58.0)

@onready var _pitch_pivot: Node3D = $PitchPivot


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		_pitch_pivot.rotation.x = clampf(_pitch_pivot.rotation.x, pitch_min, pitch_max)


func _physics_process(delta: float) -> void:
	var look_x := Input.get_axis(&"look_left", &"look_right")
	var look_y := Input.get_axis(&"look_up", &"look_down")
	if absf(look_x) < 0.01 and absf(look_y) < 0.01:
		return
	rotate_y(-look_x * stick_sensitivity * delta)
	_pitch_pivot.rotate_x(-look_y * stick_sensitivity * delta)
	_pitch_pivot.rotation.x = clampf(_pitch_pivot.rotation.x, pitch_min, pitch_max)
