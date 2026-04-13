class_name PlayerState
extends Node

const MOVE_SPEED := 5.0

var player: CharacterBody3D
var animation_tree: AnimationTree


func bind_context(body: CharacterBody3D) -> void:
	player = body
	animation_tree = body.get_node_or_null("AnimationTree") as AnimationTree


func enter() -> void:
	pass


func exit() -> void:
	pass


## Return next state's node name as StringName, or &"" to stay.
func physics_update(_delta: float) -> StringName:
	return &""
