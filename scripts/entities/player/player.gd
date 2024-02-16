class_name Player extends CharacterBody3D

@export_category("Player")

@export_group("Movement")
## The player's base movement speed.
@export_range(0, 35, 0.1, "or_greater") var speed: float = 10
## The rate at which the player accelerates from standing still to moving at
## full speed.
@export_range(0, 100, 0.1) var acceleration: float = 100
## The absolute fastest that the player can travel in each direction.
@export var max_speed := Vector3(100, 100, 100)
## The rate at which the velocity imparted by knockback "decays" towards zero.
@export_range(0, 100, 0.1) var knockback_drag: float = 10
## Self-explanatory.
@export_range(0.1, 3.0, 0.1, "or_greater") var jump_height: float = 1

@export_group("Camera")
## The sensitivity multiplier for looking around with the mouse.
#@export_range(0.1, 10.0, 0.1, "or_greater") var camera_sens: float = 12.0
## The roll angle, in degrees, that the camera turns toward when strafing.
@export_range(0.0, 15.0, 0.1, "or_greater", "radians") var roll_intensity: float = 0.052
## The rate at which the camera tilt experiened while strafing is applied.
@export_range(0.0, 1.0) var roll_speed: float = 0.5
## The frequency of the camera's horizontal movement when walking.
@export var sway_speed: float = 5.0
## The amplitude of the camera's horizontal movement when walking. (The camera's
## vertical amplitude is half this, resulting in the camera moving in a
## figure-eight pattern.)
@export var sway_height: float = 0.3
## While airborne, the weapon's apparent position (produced by manipulating the
## camera's transform position and vertical offset) corresponds to the player's
## current falling speed, multiplied by this.
@export var jump_sway: float = 0.01

@export_group("Sounds")
## The audio stream that plays when the player attempts to interact with an
## interactable object.
@export var interact_stream: AudioStream
## The audio stream that plays when the player jumps.
@export var jump_stream: AudioStream

var jumping: bool = false
static var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 ## Input direction for movement.
var look_dir: Vector2 ## Input direction for look/aim.

@export_group("Save Data")
@export var walk_vel: Vector3 ## The current walking velocity vector.
@export var grav_vel: Vector3 ## The current gravity velocity vector.
@export var jump_vel: Vector3 ## The current jumping velocity vector.
@export var knockback_vel: Vector3 ## The current knockback velocity vector.

var camera_zoom_sens: float = 1.0
var reorienting: bool = false
var sway_timer: float = PI/2

@onready var camera: Camera3D = find_child("PlayerCam")
@onready var camera_sync: Node3D = find_child("PlayerSync")
@onready var flashlight: SpotLight3D = find_child("Flashlight")
@onready var interact_scan: RayCast3D = find_child("Interact")
@onready var stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	capture_mouse()


func _process(_delta) -> void:
	if Input.is_action_pressed("jump") and is_on_floor():
		stream_player.stream = jump_stream
		stream_player.play()
		jumping = true

	if (
			Input.is_action_just_pressed("interact") and
			interact_scan.is_colliding() and
			interact_scan.get_collider().has_method("interact")
	):
		stream_player.stream = interact_stream
		stream_player.play()
		interact_scan.get_collider().interact(self)

	if Input.is_action_just_pressed("quick_restart"):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("quick_save"):
		Globals.save_game(Globals.C_QUICKSAVE_PATH)

	if Input.is_action_just_pressed("quick_load"):
		var q: PackedScene = load(Globals.C_QUICKSAVE_PATH)
		if q != null:
			get_tree().change_scene_to_packed(q)

	camera_sync.global_transform = global_transform


func _physics_process(delta: float) -> void:
	# Check if my camera rotation is valid
	if is_on_floor() and not reorienting and (
			camera.rotation.x < -PI / 2 or
			camera.rotation.x > PI / 2
	):
		reorienting = true

	# If not, perform somersaults until it is
	if reorienting:
		camera.rotation.x -= PI * delta
		if camera.rotation.x < -PI: # To prevent excessive somersaulting
			camera.rotation.x += 2 * PI
		if camera.rotation.x > PI: # To prevent excessive somersaulting
			camera.rotation.x -= 2 * PI
		# To prevent eternal somersaulting
		if camera.rotation.x < 0.1 and camera.rotation.x > -0.1:
			reorienting = false

	# Handle actually moving
	if mouse_captured: _handle_joypad_camera_rotation(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta) + _knockback(delta)
	velocity.clamp(-max_speed, max_speed)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured:
			_rotate_camera(camera_zoom_sens)


static func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


static func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


func _rotate_camera(sens_mod: float = 1.0) -> void:
#	print(camera.rotation)
	rotation.y -= look_dir.x * Globals.s_camera_sensitivity * sens_mod
	if is_on_floor() and not reorienting:
		camera.rotation.x = clamp(
				camera.rotation.x - look_dir.y * Globals.s_camera_sensitivity * sens_mod,
				-1.5,
				1.5
		)
	else:
		camera.rotation.x -= look_dir.y * Globals.s_camera_sensitivity * sens_mod


func _handle_joypad_camera_rotation(delta: float, sens_mod: float = 1.0) -> void:
	var joypad_dir: Vector2 = Input.get_vector("look_left","look_right","look_up","look_down")
	if joypad_dir.length() > 0:
		look_dir += joypad_dir * delta
		_rotate_camera(sens_mod * camera_zoom_sens)
		look_dir = Vector2.ZERO


func apply_knockback(amount: Vector3) -> void:
	if amount.y < 0:
		jump_vel = Vector3.ZERO
		grav_vel = Vector3.ZERO
		jumping = false
	knockback_vel += amount
#	print("knockback applied")


func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var _forward: Vector3 = transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()

	# Roll camera while strafing
	camera.rotation.z = move_toward(
			camera.rotation.z,
			move_dir.x * -roll_intensity,
			delta * roll_speed
	)

	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)

	if move_dir.length() <= Globals.C_EPSILON:
		sway_timer = PI/2 #smoothstep(sway_timer, PI/2, delta)
	else:
		sway_timer += delta

	# Handle camera & weapon sway/jump lag
	camera.position = Vector3(
			move_dir.length() * sway_height * cos(sway_speed * sway_timer),
			0.5 + (move_dir.length() * sway_height / 3 * sin(
					2 * sway_speed * sway_timer
			)),
			0
	) if is_on_floor() else Vector3(
			0,
			0.5 - clampf((grav_vel.y + jump_vel.y) * jump_sway, -0.1, 0.1),
			0
	)
	# Manipulating the v_offset like this makes it look like the weapon is
	# moving relative to the camera
	camera.v_offset = (
			move_dir.length() * -sway_height / 6 * sin(10 * sway_timer)
	) if is_on_floor() else clampf(
			(grav_vel.y + jump_vel.y) * jump_sway,
			-0.1,
			0.1
	)

	return walk_vel


func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(
			Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel


func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		reorienting = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(
			Vector3.ZERO, gravity * delta)
	return jump_vel


func _knockback(delta: float) -> Vector3:
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, knockback_drag * delta)
	return knockback_vel
