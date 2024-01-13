extends Area3D

@export var targets: Array[AnimationTree] = []
@export var one_way: bool = false
@export_range(-1, 2) var required_key: int = -1
@export var current_state: bool = false

signal interacted


func start() -> void:
#	targets.append_array(find_children("*", "AnimationTree"))
	for anim in targets:
		anim.get("parameters/playback").start("on" if current_state else "off")


func interact(body: Node3D) -> void:
	if required_key == -1 or body.find_child("Status").held_keys[required_key]:
		interacted.emit()
		current_state = true if one_way else not current_state
		print(current_state)
		for anim in targets:
			anim.get("parameters/playback").travel("on" if current_state else "off")
