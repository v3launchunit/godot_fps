class_name Hitscan extends Node3D

@export_category("Hitscan")

@export_flags_3d_physics var layer_mask: int = 69
@export_range(0.0, 1000.0, 0.1, "or_greater", "or_less") var max_range: float = 1000.0
@export_range(0.0, 1000.0, 0.1, "or_greater") var damage: float = 10.0
@export var explosion: PackedScene
@export_range(0.0, 100.0, 0.1, "or_greater") var knockback_force: float = 1.0
#@export var from_camera: bool = true
@export var piercer: bool = false
@export_range(0.0, 100.0, 0.1, "or_greater") var fade_speed: float = 50.0

# Defaults to some ridiculous coordinate b/c vector3 apparently isn't nullable
# (this could theoretically be solved by not declaring a type but that is a far
# worse sin in my eyes)
var query_origin := Vector3(0.0, -1000.0, 0.0)
var handled: bool = false
var exceptions: Array = []
var invoker: Node3D
#var camera: Camera3D

@onready var mesh: Node3D = get_node("MeshInstance3D") as Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	if query_origin.distance_squared_to(Vector3(0.0, -1000.0, 0.0)) <= Globals.C_EPSILON:
		query_origin = global_position
	exceptions.append(invoker)
	#if from_camera:
		#camera = get_tree().root.find_child("Camera") as Camera3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if handled:
		mesh.scale.z -= fade_speed * delta
		if mesh.scale.z < Globals.C_HITSCAN_MIN_LENGTH:
			queue_free()


func _physics_process(_delta: float) -> void:
	if handled:
		return

	handled = true
	var space = get_world_3d().direct_space_state
				#camera.global_position if from_camera
				#else global_position
		#)
	print(query_origin)
	var query = PhysicsRayQueryParameters3D.create(
			query_origin,
			query_origin - (max_range * global_transform.basis.z),
			layer_mask
	)
	if not (exceptions.is_empty() or exceptions[0] == null):
		query.set_exclude(exceptions)

	var result: Dictionary = space.intersect_ray(query)

	if result:
		mesh.global_position = result.position
		mesh.scale.z = result.position.distance_to(global_position)
		mesh.look_at(global_position)

		#if result.collider.name == "Shield":
			#print("hit shield")
			#exceptions.append(result.collider)
			#handled = false

		if result.collider.has_node("Status"):
			var status: Status = result.collider.find_child("Status")
			if (
					result.collider is EnemyBase
					and invoker != null
					and invoker != result.collider
			):
				result.collider.detect_target(invoker)
				result.collider.apply_knockback(knockback_force * (
						result.collider.global_position - global_position
				).normalized())

			damage -= status.damage(damage)
			exceptions.append(result.collider)
			if damage > 0 and piercer:
				handled = false

		var exp: Node3D = explosion.instantiate()
		get_tree().root.get_child(Globals.C_AUTOLOAD_COUNT).add_child(exp)
		exp.global_position = result.position
		if exp.find_child("Area3D") is AreaDamage:
			exp.find_child("Area3D").invoker = invoker

	else: # if the bullet didn't hit anything
		mesh.global_position = global_position + max_range * global_transform.basis.z
		mesh.scale.z = max_range - 1
		mesh.look_at(global_position)
