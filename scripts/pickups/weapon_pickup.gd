extends Pickup

@export_category("WeaponPickup")

## The weapon that will be recieved upon collecting this pickup.
@export_file("*.tscn") var weapon: String
## The amount of ammunition that will be recieved upon collecting this pickup.
## The recieved ammo's type is determined automatically based on the primary
## ammo of the associated weapon. If the player does not already possess this
## weapon, they are guarenteed to recieve the associated ammunition, regardless
## of how much ammo of that type they already possess.
@export var starting_ammo: int = 0
## Ditto, but for secondary-fire weapons. Ignored if the weapon is not
## [WeaponAltFire].
@export var starting_alt_ammo: int = 0

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
			if instance.get_child(0) is WeaponAltFire:
				manager.force_add_ammo(instance.get_child(0).alt_ammo_type, starting_alt_ammo)
			picked_up(body)
		elif (
				manager.add_ammo(instance.get_child(0).ammo_type, starting_ammo)
				or instance.get_child(0) is WeaponAltFire
				and manager.add_ammo(instance.get_child(0).alt_ammo_type, starting_alt_ammo)
		):
			instance.queue_free()
			picked_up(body)
		else:
			instance.queue_free()
