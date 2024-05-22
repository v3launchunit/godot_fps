extends Pickup

@export_category("HealthPickup")

@export var heal_amount: int = 20
@export var can_overheal: bool = false
@export var is_armor_pickup: bool = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func interact(body: Node3D) -> void:
	if body.name == "Player" and body.find_child("Status").heal(
			heal_amount,
			can_overheal,
			is_armor_pickup
	):
		picked_up(body)
