@tool

class_name BrushDoor
extends AnimatableBody3D

@export var properties: Dictionary
@export var configured: bool = false

var open: bool = false
var audio_player: AudioStreamPlayer3D
#var nav_link: NavigationLink3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if properties.get("group") != "null":
		add_to_group(properties.get("group"), true)

	audio_player = AudioStreamPlayer3D.new()
	audio_player.bus = "World"
	audio_player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	audio_player.stream = load(properties.get("sound_file"))
	add_child(audio_player)
	#audio_player.position = properties.get("sound_pos") #* 0.0625
	audio_player.position = get_child(1).shape.points[0]

	#nav_link = NavigationLink3D.new()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() and not configured:
		get_child(0).layers = 2
		#get_child(0).set_layer_mask_value(1, false)
		#get_child(0).set_layer_mask_value(2, true)
		return
	position = position.move_toward(
			properties.get("open_pos") if open else Vector3.ZERO,
			delta * properties.get("open_speed")
	)


func interact(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if (
			(open and not properties.get("closeable")) # door is open and not closable
			or (
					properties.get("required_key") != -1 # door requires key
					and not body.find_child("Status").held_keys[
							properties.get("required_key") # player doesn't have the right key
					]
			)
	):
		return
	else:
		open = not open
		audio_player.play()
