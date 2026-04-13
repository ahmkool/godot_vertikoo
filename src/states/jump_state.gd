extends PlayerState


func enter() -> void:
	player.apply_jump_impulse()
	var animation_state_machine = animation_tree["parameters/playback"]
	animation_state_machine.travel("JumpUp")


func physics_update(delta: float) -> StringName:
	if not player.is_moving_upward_relative_to_gravity():
		return &"Fall"

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length_squared() > 0.01:
		var direction: Vector3 = player.get_move_direction(input_dir)
		player.smooth_rotate_toward_move_direction(direction, delta)
		player.set_horizontal_velocity_from_direction(direction, MOVE_SPEED)

	player.apply_air_gravity(delta)
	player.move_and_slide()
	if player.is_on_floor():
		return &"Idle"
	var blend_target := clampf(input_dir.length(), 0.0, 1.0) if input_dir.length_squared() > 0.01 else 0.0
	player.update_ground_locomotion_blend(blend_target, delta)
	return &""
