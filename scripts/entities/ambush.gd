class_name AmbushPoint3D extends Marker3D

## Instantiates a scene when the player enters the set area.

@export_category("AmbushPoint3D")

## The scene to be instantiated when this node's ambush is triggered.
@export var ambusher: PackedScene:
	set(p_ambusher):
		if p_ambusher != ambusher:
			ambusher = p_ambusher
			update_configuration_warnings()
## If true (and applicable), then this node's ambusher will have its target set
## to the ambushed player as soon as it is instantiated.
@export var auto_target: bool = false
## The vertical offset with which this node's ambusher is to be instantiated.
@export var y_offset: float = 1
## This node's ambush will be triggered as soon as a player enters this Area3D
## for the first time.
@export var trigger: Area3D:
	set(p_trigger):
		if p_trigger != trigger:
			trigger = p_trigger
			update_configuration_warnings()


func _ready() -> void:
	if trigger != null && ambusher != null:
		trigger.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(_body: Node3D) -> void:
	if _body is Player:
		var a: Node3D = ambusher.instantiate()
		add_child(a)
		a.position += Vector3(0, y_offset, 0)
		a.reparent(get_parent_node_3d())
		if auto_target and a.has_method("detect_target"):
			a.detect_target(_body)
		if a is Hitscan:
			a.query_origin = a.global_position
		queue_free()


func _get_configuration_warnings():
	var warnings = []
	if ambusher == null:
		warnings.append("This ambush does not have an ambusher set.")
	if trigger == null:
		warnings.append("This ambush does not have a trigger set.")
	# Returning an empty array means "no warning".
	return warnings
