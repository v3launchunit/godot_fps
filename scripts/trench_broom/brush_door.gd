#@tool

class_name BrushDoor
extends AnimatableBody3D

@export var properties: Dictionary
@export var configured: bool = false

var center := Vector3.UP * 1000.0
var open: bool = false
var audio_player: AudioStreamPlayer3D
var nav_link: NavigationLink3D

@onready var start_pos: Vector3 = global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if Engine.is_editor_hint():
		#return

	for point: Vector3 in get_child(1).shape.points:
		#center.x += point.x
		if point.y < center.y:
			center.y = point.y
		#center.z += point.z
	#center.x /= get_child(1).shape.points.size()
	center.x = global_position.x
	center.y += 0.5 - properties.get("open_pos").y
	center.z = global_position.z
	#center.z /= get_child(1).shape.points.size()

	if properties.get("group") != "none":
		for member in get_tree().get_nodes_in_group(properties["group"]):
			if member.has_signal("interacted"):
				member.interacted.connect(toggle)
		add_to_group(properties.get("group"), true)

	audio_player = AudioStreamPlayer3D.new()
	audio_player.bus = "World"
	audio_player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	audio_player.stream = load(Globals.parse_names("sounds", properties.get("open_sound")))
	add_child(audio_player)
	#audio_player.position = properties.get("sound_pos") #* 0.0625
	audio_player.position = get_child(1).shape.points[0]

	nav_link = NavigationLink3D.new()
	nav_link.start_position = center + properties.get("nav_link_offset")
	nav_link.end_position = center - properties.get("nav_link_offset")
	add_child(nav_link)
	#nav_link.reparent(get_tree().current_scene)


func _physics_process(delta: float) -> void:
	if nav_link != null:
		nav_link.enabled = open
	#if Engine.is_editor_hint() and not configured:
		#get_child(0).layers = 2
		##get_child(0).set_layer_mask_value(1, false)
		##get_child(0).set_layer_mask_value(2, true)
		#return
	global_position = global_position.lerp(
			start_pos + properties.get("open_pos") if open else start_pos,
			delta * properties.get("open_speed")
	)


func on_triggered(by: Node3D) -> void:
	toggle(by)


func interact(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if (
			(open and not properties.get("closeable")) # door is open and not closable
			or properties["remote_only"]
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


func toggle(_body: Node3D) -> void:
	open = not open
	audio_player.play()


func set_open(to: bool) -> void:
	if open != to:
		audio_player.play()
	open = to
