extends CharacterBody3D

@onready var look_pivot: Node3D = $LookPivot
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var _body_visual: Node3D = $Root
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D

## Capsule center offset in [Root] local space (captured from the scene on ready).
var _hitbox_offset_root_local := Vector3.ZERO

## Higher = snappier turn toward move direction (camera-relative), similar to UE mannequin feel.
@export var facing_rotation_strength := 10.0
## Add PI/2 etc. if the mesh faces a different default axis than movement.
@export var facing_yaw_offset := 0.0

## Ground state BlendSpace1D: 0 = idle, 1 = run. Higher = faster blend toward target.
@export var ground_locomotion_blend_speed := 10.0

## Initial upward speed when leaving the ground (higher = taller jump).
@export var jump_velocity := 9.0
## Gravity multiplier while moving upward and jump is still held (apex control).
@export var gravity_scale_rising := 1.15
## Gravity multiplier while falling — higher = less float, snappier landings.
@export var gravity_scale_falling := 2.65
## Extra gravity while still moving up but jump is released (short hop / Mario-style cut).
@export var gravity_scale_jump_cut := 3.2

const _GROUND_BLEND_PARAM := &"parameters/Ground/blend_position"

var _ground_locomotion_blend := 0.0

var _gravity_shift_started := false
## Wall-clock start of blend; -1 = not blending (uses locked or engine gravity).
var _gravity_shift_begin_usec := -1
var _gravity_interp_duration := 1.0
var _gravity_interp_from := Vector3.ZERO
var _gravity_interp_to := Vector3.ZERO
## Final acceleration after the core transition; kept when leaving the area.
var _gravity_locked := Vector3.ZERO


func _ready() -> void:
	if _collision_shape:
		_hitbox_offset_root_local = _collision_shape.position


## Runs before child nodes (e.g. StateMachine) so [up_direction] is current before [move_and_slide].
func _physics_process(_delta: float) -> void:
	align_to_gravity()


## Keeps the CharacterBody3D hitbox aligned with [Root] rotation (must stay a direct child of the body).
func sync_collision_with_visual() -> void:
	if _collision_shape == null or _body_visual == null:
		return
	var b := _body_visual.transform.basis.orthonormalized()
	_collision_shape.transform = Transform3D(b, b * _hitbox_offset_root_local)


## Call from the gravity core once; blends from current engine gravity to [target_accel], then locks it.
func begin_permanent_gravity_shift(target_accel: Vector3, duration: float = 1.0) -> void:
	if _gravity_shift_started:
		return
	_gravity_shift_started = true
	_gravity_interp_from = get_gravity()
	_gravity_interp_to = target_accel
	_gravity_interp_duration = maxf(duration, 0.0001)
	_gravity_shift_begin_usec = Time.get_ticks_usec()
	_gravity_locked = Vector3.ZERO


func get_simulated_gravity() -> Vector3:
	if _gravity_shift_begin_usec >= 0:
		var elapsed := (Time.get_ticks_usec() - _gravity_shift_begin_usec) / 1_000_000.0
		var t := clampf(elapsed / _gravity_interp_duration, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		var g := _gravity_interp_from.lerp(_gravity_interp_to, t)
		if elapsed >= _gravity_interp_duration:
			_gravity_locked = _gravity_interp_to
			_gravity_shift_begin_usec = -1
		return g
	if _gravity_locked.length_squared() > 0.0001:
		return _gravity_locked
	return get_gravity()


func get_effective_up_direction() -> Vector3:
	var g := get_simulated_gravity()
	if g.length_squared() < 0.0001:
		return Vector3.UP
	return -g.normalized()


func _uses_simulated_gravity() -> bool:
	return _gravity_shift_begin_usec >= 0 or _gravity_locked.length_squared() > 0.0001


func get_move_direction(input_dir: Vector2) -> Vector3:
	if look_pivot == null:
		return (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var dir := look_pivot.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	if dir.length_squared() < 0.0001:
		return Vector3.ZERO
	return dir.normalized()


## Uprights [Root] relative to gravity and yaws toward [direction] (movement intent only; never camera-locked).
func update_body_visual_orientation(direction: Vector3, delta: float) -> void:
	if _body_visual == null:
		return
	if direction.length_squared() < 0.0001:
		return
	var g := get_simulated_gravity()
	var up: Vector3 = Vector3.UP if g.length_squared() < 0.0001 else (-g.normalized())
	var horiz: Vector3 = direction - up * direction.dot(up)
	if horiz.length_squared() < 0.0001:
		return
	horiz = horiz.normalized()
	var inv := transform.basis.inverse()
	var h_local := inv * horiz
	var u_local := inv * up
	if h_local.length_squared() < 0.0001:
		return
	h_local = h_local.normalized()
	u_local = u_local.normalized()
	var target_basis := Basis.looking_at(h_local, u_local, true)
	var tq := target_basis.get_rotation_quaternion()
	if absf(facing_yaw_offset) > 0.0001:
		tq = Quaternion(u_local, facing_yaw_offset) * tq
	var q := _body_visual.transform.basis.get_rotation_quaternion()
	if q.angle_to(tq) < 0.002:
		return
	var w := 1.0 - exp(-facing_rotation_strength * delta)
	_body_visual.transform.basis = Basis(q.slerp(tq, w).normalized()).orthonormalized()


## Smoothly yaw the mesh toward horizontal movement, without rotating the camera rig.
func smooth_rotate_toward_move_direction(direction: Vector3, delta: float) -> void:
	update_body_visual_orientation(direction, delta)


func set_ground_locomotion_blend_immediate(amount: float) -> void:
	if animation_tree == null:
		return
	_ground_locomotion_blend = clampf(amount, 0.0, 1.0)
	animation_tree.set(_GROUND_BLEND_PARAM, _ground_locomotion_blend)


## Smooth 0–1 blend for the Ground state's BlendSpace1D (idle ↔ run).
func update_ground_locomotion_blend(target: float, delta: float) -> void:
	if animation_tree == null:
		return
	target = clampf(target, 0.0, 1.0)
	_ground_locomotion_blend = move_toward(
		_ground_locomotion_blend,
		target,
		ground_locomotion_blend_speed * delta
	)
	animation_tree.set(_GROUND_BLEND_PARAM, _ground_locomotion_blend)


func align_to_gravity() -> void:
	var next_up := get_effective_up_direction()
	if next_up.length_squared() < 0.0001:
		next_up = Vector3.UP
	else:
		next_up = next_up.normalized()
	var prev_up := up_direction
	up_direction = next_up
	if not prev_up.is_equal_approx(next_up):
		# CharacterBody3D only refreshes floor state after [move_and_slide]; snapping helps in air.
		if not is_on_floor():
			apply_floor_snap()


func is_moving_upward_relative_to_gravity() -> bool:
	var g := get_simulated_gravity()
	if g.length_squared() < 0.0001:
		return velocity.y > 0.0
	var up := -g.normalized()
	return velocity.dot(up) > 0.0


## Preserves speed along gravity; sets horizontal part from [direction] on the floor plane.
func set_horizontal_velocity_from_direction(direction: Vector3, speed: float) -> void:
	var g := get_simulated_gravity()
	if g.length_squared() < 0.0001:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		return
	var up := -g.normalized()
	var v_along := velocity.dot(up)
	var horiz: Vector3 = direction - up * direction.dot(up)
	if horiz.length_squared() > 0.0001:
		horiz = horiz.normalized() * speed
	else:
		horiz = Vector3.ZERO
	velocity = up * v_along + horiz


func decay_horizontal_velocity(amount: float) -> void:
	var g := get_simulated_gravity()
	if g.length_squared() < 0.0001:
		velocity.x = move_toward(velocity.x, 0.0, amount)
		velocity.z = move_toward(velocity.z, 0.0, amount)
		return
	var up := -g.normalized()
	var v_along := velocity.dot(up)
	var horiz := velocity - up * v_along
	var h_len := horiz.length()
	if h_len < 0.0001:
		return
	var new_len := move_toward(h_len, 0.0, amount)
	horiz = horiz.normalized() * new_len if new_len > 0.0001 else Vector3.ZERO
	velocity = up * v_along + horiz


func apply_jump_impulse() -> void:
	var g := get_simulated_gravity()
	if g.length_squared() < 0.0001:
		velocity.y = jump_velocity
		return
	var up := -g.normalized()
	velocity -= up * velocity.dot(up)
	velocity += up * jump_velocity


## Airborne gravity with asymmetric rise/fall and optional jump-cut when releasing jump early.
func apply_air_gravity(delta: float) -> void:
	var g := get_simulated_gravity()
	if g.length_squared() < 0.0001:
		return
	var g_n := g.normalized()
	var v_along := velocity.dot(g_n)
	var mult: float
	if v_along >= 0.0:
		mult = gravity_scale_falling
	elif Input.is_action_pressed(&"ui_accept"):
		mult = gravity_scale_rising
	else:
		mult = gravity_scale_jump_cut
	velocity += g * mult * delta
