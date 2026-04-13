extends PlayerState


func physics_update(delta: float) -> StringName:
	if not player.is_on_floor():
		player.apply_air_gravity(delta)
		player.move_and_slide()
		return &"Fall"

	if Input.is_action_just_pressed("ui_accept"):
		return &"Jump"

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length_squared() < 0.01:
		return &"Idle"

	var direction: Vector3 = player.get_move_direction(input_dir)
	player.smooth_rotate_toward_move_direction(direction, delta)
	player.set_horizontal_velocity_from_direction(direction, MOVE_SPEED)
	player.move_and_slide()
	var run_amount := clampf(input_dir.length(), 0.0, 1.0)
	player.update_ground_locomotion_blend(run_amount, delta)
	return &""
