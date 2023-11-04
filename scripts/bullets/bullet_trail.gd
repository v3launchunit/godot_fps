extends GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_bullet_body_entered(_body):
	reparent(get_tree().root)
	emitting = false
	await get_tree().create_timer(lifetime).timeout
	queue_free()
