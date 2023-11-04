extends Node

@export_category("Lifetime")

@export var lifetime: float = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
