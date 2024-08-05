@tool

extends ReflectionProbe


@export var properties: Dictionary:
	set(to):
		properties = to
		max_distance = properties["max_distance"]
		size = properties["size"]
		origin_offset = properties["origin_offset"]
		box_projection = properties["box_project"]
		interior = properties["interior"]
		enable_shadows = properties["reflect_shadows"]
		cull_mask = 0b0000_0000_0000_1001


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
