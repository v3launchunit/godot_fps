extends Area3D

@onready var destination: Vector3 = find_child("Destination").global_position
@onready var nav_link: NavigationLink3D = find_child("NavigationLink3D")
@onready var streams: Array[Node] = find_children("AudioStreamPlayer3D")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	nav_link.set_global_end_position(destination)
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
#	print("teleported " + body.name)
	body.global_position = destination
	for stream in streams:
		stream.play()
