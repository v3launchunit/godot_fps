extends RigidBody3D

@export_category("AmmoPickup")

@export var ammo_type: String = "none"
@export var ammo_amount: int = 1
@export var flash_color: Color = Color.YELLOW
@export var pickup_sound: AudioStream

@onready var area: Area3D = find_child("Area3D")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area.body_entered.connect(_pickup)
	find_child("AnimationPlayer").play("anim")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _pickup(body: Node3D) -> void:
	if body.name == "Player" and body.find_child("PlayerCam").add_ammo(ammo_type, ammo_amount):
		if pickup_sound != null:
			body.find_child("HUD").flash_with_sound(flash_color, pickup_sound)
		else:
			body.find_child("HUD").flash(flash_color)
		queue_free()
