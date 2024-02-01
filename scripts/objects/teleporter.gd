extends Area3D

@onready var destination: Vector3 = find_child("Destination").global_position
@onready var nav_link: NavigationLink3D = find_child("NavigationLink3D")
@onready var streams: Array[Node] = find_children("AudioStreamPlayer3D")
@onready var tele_sys: Array[Node] = find_children("TeleportSys")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	nav_link.set_global_end_position(destination)
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	if tele_sys[0].get_child(0).visible:
#		for sys in tele_sys:
#			sys.get_child(0).light_energy -= delta
#			if sys.get_child(0).light_energy <= 0:
#				sys.get_child(0).hide()


func _on_body_entered(body: Node3D) -> void:
#	print("teleported " + body.name)
	body.global_position = destination
	for stream in streams:
		stream.play()

	for sys in tele_sys:
		sys.emitting = true
		sys.restart()
#		sys.get_child(0).light_energy = 3.0
#		sys.get_child(0).show()
