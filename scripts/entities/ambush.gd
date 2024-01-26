class_name AmbushPoint3D extends Marker3D

@export_category("AmbushPoint3D")

## The scene to be instantiated when this node's ambush is triggered.
@export var ambusher: PackedScene
## If true (and applicable), then this node's ambusher will have its target set
## to the ambushed player as soon as it is instantiated.
@export var auto_target: bool = false
## The vertical offset with which this node's ambusher is to be instantiated.
@export var y_offset: float = 1
## This node's ambush will be triggered as soon as a player enters this Area3D
## for the first time.
@export var trigger: Area3D


func _ready() -> void:
	trigger.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(_body: Node3D) -> void:
	var a: Node3D = ambusher.instantiate()
	add_child(a)
	a.position += Vector3(0, y_offset, 0)
	a.reparent(get_parent_node_3d())
	if auto_target:
		a.detect_target(_body)
	queue_free()
