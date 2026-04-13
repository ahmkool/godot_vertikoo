extends Node

@export var initial_state: NodePath = ^"Idle"

var _current: PlayerState


func _ready() -> void:
	# Lower [process_physics_priority] runs first; keep this after the body's [align_to_gravity].
	process_physics_priority = 1
	var body := get_parent() as CharacterBody3D
	for child in get_children():
		if child is PlayerState:
			(child as PlayerState).bind_context(body)
	if not has_node(initial_state):
		push_error("StateMachine: missing initial state at %s" % str(initial_state))
		return
	_current = get_node(initial_state) as PlayerState
	if _current == null:
		push_error("StateMachine: initial state is not a PlayerState")
		return
	var at := body.get_node_or_null("AnimationTree") as AnimationTree
	if at:
		at.active = true
	_current.enter()


func _physics_process(delta: float) -> void:
	if _current == null:
		return
	var body := get_parent()
	var next: StringName = _current.physics_update(delta)
	if body is CharacterBody3D and body.has_method(&"sync_collision_with_visual"):
		body.sync_collision_with_visual()
	if next != &"" and has_node(NodePath(str(next))):
		_current.exit()
		_current = get_node(NodePath(str(next))) as PlayerState
		print("Transitioning to %s" % str(next))
		_current.enter()
