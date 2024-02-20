extends Pickup

@export_category("KeyPickup")

@export_range(0, 2) var key_type: int = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func interact(body: Node3D) -> void:
	if body.name == "Player":
		body.find_child("Status").key_acquired.emit(key_type)
		picked_up(body)
