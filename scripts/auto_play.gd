extends AnimationPlayer

@export_category("AutoPlay")

@export var animated_materials: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	var fog: FogVolume = find_child("FogVolume")
#	fog.material = fog.material.duplicate()
#	fog.global_position = get_parent().global_position
	
	for item in animated_materials:
		if get_node(item) is MeshInstance3D:
			get_node(item).mesh = get_node(item).mesh.duplicate()
			get_node(item).mesh.material = get_node(item).mesh.material.duplicate()
		else:
			get_node(item).material = get_node(item).material.duplicate()
		get_node(item).global_position = get_parent().global_position
	
#	var particles: GPUParticles3D = find_child("GPUParticles3D")
#	particles.emitting = true
#	particles.global_position = get_parent().global_position
	
	play("anim")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
