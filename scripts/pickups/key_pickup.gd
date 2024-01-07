extends RigidBody3D

@export_category("KeyPickup")

@export_range(0, 2) var key_type: int = 0
@export var flash_color: Color = Color.RED
@export var pickup_sound: AudioStream

@onready var area: Area3D = find_child("Area3D")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area.body_entered.connect(interact)
	find_child("AnimationPlayer").play("anim")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact(body: Node3D) -> void:
	if body.name == "Player":
		body.find_child("Status").key_acquired.emit(key_type)
		if pickup_sound != null:
			body.find_child("HUD").flash_with_sound(flash_color, pickup_sound)
		else:
			body.find_child("HUD").flash(flash_color)
		queue_free()
