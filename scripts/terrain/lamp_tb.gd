extends MeshInstance3D

## Trenchbroom Properties
## Vector3 color
## Float energy
## Float range
@export var properties: Dictionary

func _ready() -> void:
	var color := Color(
			properties.get("color").x / 255,
			properties.get("color").y / 255,
			properties.get("color").z / 255,
			1.0,
	)
	material_override = mesh.material#.duplicate()

	set_instance_shader_parameter("albedo", color * properties.get("energy"))
	get_child(0).light_color = color
	get_child(0).light_energy = properties.get("energy")
	get_child(0).omni_range = properties.get("range")
	get_child(0).get_child(0).color = color
