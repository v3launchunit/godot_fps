extends Node3D

@onready var low_cast: ShapeCast3D = $LowCast as ShapeCast3D
@onready var high_cast: ShapeCast3D = $HighCast as ShapeCast3D
@onready var body: CharacterBody3D = get_parent_node_3d() as CharacterBody3D
#@onready var step_cast: ShapeCast3D = $StepCast as ShapeCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	low_cast.target_position = (
			body.velocity.normalized()
			* body.transform.basis
	) * Vector3(1.0, 0.0, 1.0)
	high_cast.target_position = (
			body.velocity.normalized()
			* body.transform.basis
	) * Vector3(1.0, 0.0, 1.0)
	if (
			body.is_on_floor()
			and body.velocity.distance_squared_to(Vector3.ZERO) >= Globals.C_EPSILON
			and low_cast.is_colliding()
			and not high_cast.is_colliding()
			#and low_cast.get_collision_normal(0).angle_to(Vector3.UP) >= body.floor_max_angle
	):
		body.translate(Vector3(0.0, 0.55, 0.0))
		body.apply_floor_snap()
				#(step_cast.global_position
				#- step_cast.get_collision_point(0))
				#* Vector3.UP
		#)
