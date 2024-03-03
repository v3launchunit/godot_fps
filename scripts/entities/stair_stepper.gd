extends Node3D

@onready var low_cast: ShapeCast3D = $LowCast as ShapeCast3D
@onready var high_cast: ShapeCast3D = $HighCast as ShapeCast3D
#@onready var step_cast: ShapeCast3D = $StepCast as ShapeCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if (
			get_parent_node_3d().is_on_floor()
			and low_cast.is_colliding()
			and not high_cast.is_colliding()
	):
		get_parent_node_3d().translate(Vector3(0.0, 0.55, 0.0))
				#(step_cast.global_position
				#- step_cast.get_collision_point(0))
				#* Vector3.UP
		#)
