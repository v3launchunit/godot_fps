extends RigidBody3D

@export_category("WeaponPickup")

@export_file("*.tscn") var weapon: String
@export var starting_ammo: int = 0
@export var flash_color: Color = Color.GREEN
@export var pickup_sound: AudioStream

@onready var weapon_scene: PackedScene = load(weapon)
@onready var area: Area3D = find_child("Area3D")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area.body_entered.connect(_pickup)
	find_child("AnimationPlayer").play("anim")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _pickup(body: Node3D) -> void:
	if body.name == "Player":
		var manager := body.find_child("PlayerCam")
		var instance := weapon_scene.instantiate()
		if manager.add_weapon(instance, starting_ammo):
			manager.force_add_ammo(instance.get_child(0).ammo_type, starting_ammo)
			manager.add_child(instance)
			if pickup_sound != null:
				body.find_child("HUD").flash_with_sound(flash_color, pickup_sound)
			else:
				body.find_child("HUD").flash(flash_color)
			queue_free()
		elif manager.add_ammo(instance.get_child(0).ammo_type, starting_ammo):
			if pickup_sound != null:
				body.find_child("HUD").flash_with_sound(flash_color, pickup_sound)
			else:
				body.find_child("HUD").flash(flash_color)
			instance.queue_free()
			queue_free()
		else:
			instance.queue_free()
