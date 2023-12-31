extends Node3D

@export_category("Hitscan")

@export_flags_3d_physics var layer_mask: int = 1
@export_range(-1000.0, 1000.0, 0.1) var range: float = 1000.0
@export_range(0.0, 100.0, 1.0) var fade_speed: float = 50.0
@export var damage: float = 10.0
@export_file("*.tscn") var explosion: String
@export var knockback_force: float = 1.0
@export var from_camera: bool = true
@export var piercer: bool = false

var handled: bool = false
var exceptions: Array = []
var invoker: Node3D

@onready var explosion_scene: PackedScene = load(explosion)

# Called when the node enters the scene tree for the first time.
func _ready():
	exceptions.append(invoker)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if handled:
		var mesh: Node3D = get_node("MeshInstance3D")
		mesh.scale.z -= fade_speed * delta
		if mesh.scale.z < 0.125:
			queue_free()


func _physics_process(delta):
	if not handled:
		handled = true
		var space = get_world_3d().direct_space_state
		var query_origin = get_viewport().get_camera_3d().global_position if \
				from_camera else global_position
		var query = PhysicsRayQueryParameters3D.create(
				query_origin, 
				query_origin + range * get_global_transform().basis.z, 
				layer_mask)
		query.set_exclude(exceptions)
		var result = space.intersect_ray(query)
		
		var mesh: Node3D = get_node("MeshInstance3D")
		if result:
			mesh.global_position = result.position
			mesh.scale.z = result.position.distance_to(global_position)
			mesh.look_at(global_position)
			
			if result.collider.name != "Shield" and result.collider.has_node("Status"):
				var status: Status = result.collider.find_child("Status")
				if result.collider is EnemyBase:
					result.collider.detect_target(invoker)
					result.collider.apply_knockback(knockback_force * \
							(result.collider.global_position - global_position).normalized())
				
				damage -= status.damage(damage)
				exceptions.append(result.collider)
				if damage > 0 and piercer:
					handled = false
			
			var exp: Node3D = explosion_scene.instantiate()
			get_tree().root.add_child(exp)
			exp.global_position = result.position
			if exp.find_child("Area3D") is AreaDamage:
				exp.find_child("Area3D").invoker = invoker
		else:
			mesh.global_position = global_position \
					+ range * get_global_transform().basis.z
			mesh.scale.z = range - 1
			mesh.look_at(global_position)
