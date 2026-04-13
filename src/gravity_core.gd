extends Node3D

@onready var _area: Area3D = $Area3D

var gravity_change_activated := false


func _ready() -> void:
	var strength := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	_area.gravity_direction = Vector3(0.0, 0.0, -1.0)
	_area.gravity = strength


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	gravity_change_activated = true
