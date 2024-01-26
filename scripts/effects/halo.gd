extends MeshInstance3D

@export var color: Color = Color.WHITE
@export var fade_time: float = 1.0
@export_flags_3d_physics var collision_mask: int = 1

var player_cam: Camera3D

@onready var material: Material = material_override


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ignore_occlusion_culling = true
	material_override = material.duplicate()
	material = material_override
	Globals.settings_changed.connect(_on_globals_settings_changed)
	_on_globals_settings_changed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	material.albedo_color = color


func _physics_process(delta: float) -> void:
	if player_cam == null: #or not visible:
		player_cam = get_tree().get_first_node_in_group("player_cam")
		return

	var space_state = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			global_position,
			player_cam.global_position,
			collision_mask,
	)
	var hit := space_state.intersect_ray(query)
	if hit:
		color.a = move_toward(color.a, 0.0, delta * fade_time)
	else:
		color.a = move_toward(color.a, 1.0, delta * fade_time)


func _on_globals_settings_changed() -> void:
	visible = Globals.s_flares_enabled
