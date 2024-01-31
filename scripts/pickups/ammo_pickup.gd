extends Pickup

@export_category("AmmoPickup")

@export var ammo_type: String = "none"
@export var ammo_amount: int = 1


func interact(body: Node3D) -> void:
	if (
			body.name == "Player"
			and body.find_child("PlayerCam").add_ammo(ammo_type, ammo_amount)
	):
		picked_up(body)
