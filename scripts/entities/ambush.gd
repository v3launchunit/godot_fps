class_name AmbushPoint3D extends Marker3D

@export_category("AmbushPoint3D")

@export var ambusher: PackedScene
@export var y_offset: float = 1
@export var trigger: Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	trigger.body_entered.connect(_on_trigger_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_trigger_body_entered(_body: Node3D) -> void:
#	print("spawning ambush")
	var a: Node3D = ambusher.instantiate()
	add_child(a)
	a.position += Vector3(0, y_offset, 0)
	a.reparent(get_parent_node_3d())
	queue_free()
