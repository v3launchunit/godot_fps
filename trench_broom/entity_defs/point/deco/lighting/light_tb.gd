@tool

extends OmniLight3D


@export var properties: Dictionary:
	set(to):
		if properties != to:
			properties = to
			update_properties()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_properties() -> void:
	light_color = Color8(
			roundi(properties.get("_color").x),
			roundi(properties.get("_color").y),
			roundi(properties.get("_color").z),
	)
	light_energy = properties["energy"]
	light_bake_mode = BakeMode.BAKE_STATIC
	shadow_enabled = true
	
	omni_range = properties["range"]
