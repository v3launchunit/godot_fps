extends Pickup

@export_category("WeaponPickup")

@export_file("*.tscn") var weapon: String
@export var starting_ammo: int = 0

@onready var weapon_scene: PackedScene = load(weapon)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact(body: Node3D) -> void:
	if body.name == "Player":
		var manager := body.find_child("PlayerCam")
		var instance := weapon_scene.instantiate()
		
		manager.add_child(instance)
		
		if manager.add_weapon(instance, starting_ammo):
			manager.force_add_ammo(instance.get_child(0).ammo_type, starting_ammo)
			picked_up(body)
		elif manager.add_ammo(instance.get_child(0).ammo_type, starting_ammo):
			instance.queue_free()
			picked_up(body)
		else:
			instance.queue_free()
