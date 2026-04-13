extends Node3D

@onready var _area: Area3D = $Area3D

## How long the gravity (and camera) blend lasts after the first overlap.
@export var transition_duration := 1.0

var gravity_change_activated := false


func _ready() -> void:
	# Gravity is driven by the player script after entry so it stays when the body leaves.
	_area.gravity_space_override = Area3D.SPACE_OVERRIDE_DISABLED


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	if not body.has_method(&"begin_permanent_gravity_shift"):
		return
	var strength := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var target := Vector3(0.0, 0.0, -1.0) * strength
	body.begin_permanent_gravity_shift(target, transition_duration)
	gravity_change_activated = true
