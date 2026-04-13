extends PlayerState


func enter() -> void:
	player.set_ground_locomotion_blend_immediate(0.0)
	var animation_state_machine = animation_tree["parameters/playback"]
	animation_state_machine.travel("Falling")


func physics_update(delta: float) -> StringName:
	if player.is_on_floor():
		var animation_state_machine = animation_tree["parameters/playback"]
		animation_state_machine.travel("Ground")
		return &"Idle"

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length_squared() > 0.01:
		var direction: Vector3 = player.get_move_direction(input_dir)
		player.smooth_rotate_toward_move_direction(direction, delta)
		player.set_horizontal_velocity_from_direction(direction, MOVE_SPEED)
	else:
		player.decay_horizontal_velocity(MOVE_SPEED * delta * 8.0)

	player.apply_air_gravity(delta)
	player.move_and_slide()
	var blend_target := clampf(input_dir.length(), 0.0, 1.0) if input_dir.length_squared() > 0.01 else 0.0
	player.update_ground_locomotion_blend(blend_target, delta)
	return &""
