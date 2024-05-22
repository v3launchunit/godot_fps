class_name Player extends CharacterBody3D

@export_category("Player")

@export_group("Movement")
## The player's base movement speed.
@export_range(0.0, 35.0, 0.1, "or_greater") var speed: float = 10.0
## The rate at which the player accelerates from standing still to moving at
## full speed.
@export_range(0.0, 100.0, 0.1, "or_greater") var acceleration: float = 100.0
## The absolute fastest that the player can travel in each direction.
@export var max_speed := Vector3(100.0, 100.0, 100.0)
## The rate at which the velocity imparted by sliding "decays" towards zero.
@export_range(0.0, 100.0, 0.1, "or_greater") var slide_drag: float = 10.0
## Ditto for knockback.
@export_range(0.0, 100.0, 0.1, "or_greater") var knockback_drag: float = 10.0
## Self-explanatory.
@export_range(0.1, 3.0, 0.1, "or_greater") var jump_height: float = 1
@export_range(1, 10, 1, "or_greater") var max_jumps: int = 1
@export_range(0.0, 100.0, 0.1, "or_greater") var rise_grav: float = 9.8
@export_range(0.0, 100.0, 0.1, "or_greater") var fall_grav: float = 9.8
@export_range(0.0, 100.0, 0.1, "or_greater") var slam_speed: float = 100.0

@export_group("Camera")
## The roll angle, in degrees, that the camera turns toward when strafing.
@export_range(0.0, 15.0, 0.1, "or_greater", "radians") var roll_intensity: float = 0.052
## The rate at which the camera tilt experiened while strafing is applied.
@export_range(0.0, 1.0, 0.001) var roll_speed: float = 0.5

## The frequency of the camera's horizontal movement when walking.
@export_range(0.0, 10.0, 0.1, "or_greater") var sway_speed: float = 5.0
## The amplitude of the camera's horizontal movement when walking. (The camera's
## vertical amplitude is half this, resulting in the camera moving in a
## figure-eight pattern.)
@export_range(0.0, 1.0, 0.001) var sway_height: float = 0.3
## While airborne, the weapon's apparent position (produced by manipulating the
## camera's transform position and vertical offset) corresponds to the player's
## current falling speed, multiplied by this.
@export_range(0.0, 1.0, 0.001) var jump_sway: float = 0.01
@export_range(0.0, 1.0, 0.001) var strafe_sway: float = 0.025
@export_range(-1.0, 1.0, 0.01) var look_drag: float = 0.25

@export_group("Sounds")
## The audio stream that plays when the player attempts to interact with an
## interactable object.
@export var interact_stream: AudioStream

## The audio stream that plays when the player jumps.
@export var jump_stream: AudioStream

var jumping: bool = false
var crouching: bool = false
var slamming: bool = false
static var mouse_captured: bool = false

var jumps: int = 1
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 ## Input direction for movement.
var look_dir: Vector2 ## Input direction for look/aim.

var walk_vel: Vector3 ## The current walking velocity vector.
var slide_vel: Vector3 ## The current sliding velocity vector.
var grav_vel: Vector3 ## The current gravity velocity vector.
var jump_vel: Vector3 ## The current jumping velocity vector.
var knockback_vel: Vector3 ## The current knockback velocity vector.

var camera_zoom_sens: float = 1.0
var reorienting: bool = false
var sway_timer: float = PI/2

var cam_recoil_pos: float = 0.0
var cam_recoil_vel: float = 0.0

var holding = null

@onready var camera := find_child("PlayerCam") as WeaponManager
@onready var camera_sync := find_child("PlayerSync") as Node3D
@onready var flashlight := find_child("Flashlight") as SpotLight3D
@onready var interact_scan := find_child("Interact") as RayCast3D
@onready var clearance_scan := $ClearanceCast as ShapeCast3D
@onready var stream_player := $AudioStreamPlayer as AudioStreamPlayer

func _ready() -> void:
	capture_mouse()


func _process(_delta) -> void:
	if jumps < max_jumps and is_on_floor():
		jumps = max_jumps

	if Input.is_action_pressed("jump") and jumps > 0:
		stream_player.stream = jump_stream
		stream_player.play()
		jumping = true

	if crouching and ((
			Globals.s_toggle_crouch
			and Input.is_action_just_pressed("crouch")
	) or not (
			Globals.s_toggle_crouch
			or Input.is_action_pressed("crouch")
	)) and not clearance_scan.is_colliding():
		_toggle_crouch(false)

	# Check if I should interact with anything
	if (
			Input.is_action_just_pressed("interact") and
			interact_scan.is_colliding() and
			interact_scan.get_collider().has_method("interact")
	):
		stream_player.stream = interact_stream
		stream_player.play()
		interact_scan.get_collider().interact(self)

	if Input.is_action_just_pressed("crouch") and not crouching:
		if not is_on_floor() and not Input.is_action_pressed("jump"):
			slamming = true
		else:
			_toggle_crouch(true)

	if Input.is_action_just_pressed("quick_restart"):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("quick_save"):
		Globals.save_game(Globals.C_QUICKSAVE_PATH)

	if Input.is_action_just_pressed("quick_load"):
		var q: PackedScene = load(Globals.C_QUICKSAVE_PATH)
		if q != null:
			get_tree().change_scene_to_packed(q)


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
		if abs(camera.rotation.x) < 0.1:
			reorienting = false

	# Handle actually moving
	if mouse_captured: _handle_joypad_camera_rotation(delta)
	velocity = (
			_walk(delta)
			+ _slide(delta)
			+ _gravity(delta)
			+ _jump(delta)
			+ _knockback(delta)
	)
	cam_recoil_pos = camera_sync.rotation.x + cam_recoil_vel
	cam_recoil_pos = smoothstep(camera_sync.rotation.x + cam_recoil_vel * delta, 0, delta)
	cam_recoil_vel = lerpf(cam_recoil_vel, 0, delta)
	camera_sync.global_transform = global_transform
	camera_sync.rotation.x = cam_recoil_pos

	velocity = velocity.clamp(-max_speed, max_speed)
	move_and_slide()

	if position.y < Globals.C_PLAYER_MIN_HEIGHT:
		position.y = -Globals.C_PLAYER_MIN_HEIGHT
		grav_vel = Vector3.ZERO


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
		slamming = false
	knockback_vel += amount
#	print("knockback applied")


func _toggle_crouch(to: bool) -> void:
	var hitbox: CollisionShape3D = $PlayerHitbox as CollisionShape3D
	var crouchbox: CollisionShape3D = $PlayerCrouchHitbox as CollisionShape3D
	if is_on_floor():
		translate(Vector3(0, -1 if to else 1, 0))
		slide_vel = walk_vel
	crouching = to
	hitbox.disabled = to
	crouchbox.disabled = not to


func _walk(delta: float) -> Vector3:
	var move_input: Vector2 = Input.get_vector(
			"move_left", "move_right", "move_forward", "move_backwards")
	move_dir = move_dir.move_toward(move_input, delta * acceleration / speed)
	var forward: Vector3 = transform.basis * Vector3(move_input.x, 0, move_input.y)
	var walk_dir := Vector3(forward.x, 0, forward.z).normalized()

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
			(
					move_dir.length() * sway_height * cos(
							sway_speed * sway_timer
					) - move_dir.x * strafe_sway
			),
			(
					0.5 + move_dir.length() * sway_height / 3 * sin(
							2 * sway_speed * sway_timer
					)
			),
			0
	) if is_on_floor() else Vector3(
			0,
			0.5 - clampf((grav_vel.y + jump_vel.y) * jump_sway, -0.1, 0.1),
			0
	)
	# Manipulating the offsets like this makes it look like the weapon is
	# moving relative to the camera without having to actually move the weapon
	camera.h_offset = move_dir.x * strafe_sway
	camera.v_offset = (
			move_dir.length() * -sway_height / 6 * sin(10 * sway_timer)
	) if is_on_floor() else clampf(
			(grav_vel.y + jump_vel.y) * jump_sway,
			-0.1,
			0.1
	)

	if (
			slamming
			and Input.is_action_just_pressed("jump")
			and move_input.length_squared() > Globals.C_EPSILON
	):
		slamming = false
		grav_vel = Vector3.ZERO
		slide_vel = walk_dir * speed/4

	return Vector3.ZERO if slamming else walk_vel


func _slide(delta: float) -> Vector3:
	if is_on_floor() or walk_vel.normalized().dot(slide_vel.normalized()) < 0.5:
		slide_vel = slide_vel.move_toward(Vector3.ZERO, delta * slide_drag)
	return Vector3.ZERO if slamming else slide_vel


func _gravity(delta: float) -> Vector3:
	if slamming:
		if is_on_floor():
			slamming = false
		else:
			grav_vel = Vector3(0, -slam_speed, 0)
	else:
		grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(
				Vector3(0, velocity.y - (
						rise_grav
						if Input.is_action_pressed("jump")
						else fall_grav
				), 0),
				(
						rise_grav
						if Input.is_action_pressed("jump")
						else fall_grav
				) * delta
		)
	return grav_vel


func _jump(delta: float) -> Vector3:
	if jumping:
		if jumps > 0:
			jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
			jumps -= 1
		jumping = false
		reorienting = false
		return jump_vel
	if is_on_floor():
		jump_vel = Vector3.ZERO
	elif not Input.is_action_pressed("jump"):
		jump_vel = jump_vel.move_toward(
				Vector3.ZERO, (
						rise_grav
						#if Input.is_action_pressed("jump")
						#else fall_grav
				) * delta)
	return jump_vel


func _knockback(delta: float) -> Vector3:
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, knockback_drag * delta)
	return knockback_vel


func _on_carriable_grabbed(what: Carriable) -> void:
	camera.switched_weapons.emit(-1, -1)
	holding = what

