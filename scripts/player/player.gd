class_name Player extends CharacterBody3D

@export_category("Player")
@export_range(0, 35, 0.1, "or_greater") var speed: float = 10 # m/s
@export_range(0, 100, 0.1) var acceleration: float = 100 # m/s^2
@export var max_speed := Vector3(100, 100, 100)
@export_range(0, 100, 0.1) var knockback_drag: float = 10

@export_range(0.1, 3.0, 0.1, "or_greater") var jump_height: float = 1
@export_range(0.1, 10.0, 0.1, "or_greater") var camera_sens: float = 3
@export_range(0.0, 15.0, 0.1, "or_greater") var roll_intensity: float = 3
@export_range(0.0, 1.0) var roll_speed: float = 0.5
@export var sway_speed: float = 5.0
@export var sway_height: float = 0.3
@export var jump_sway: float = 0.01

var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity
var knockback_vel: Vector3 # Knockback velocity

var camera_zoom_sens: float = 1.0
var reorienting: bool = false
var sway_timer: float = PI/2

@onready var camera: Camera3D = $PlayerCam
@onready var interact_scan: RayCast3D = $PlayerCam/Interact
@onready var interact_stream_player: AudioStreamPlayer = find_child("AudioStreamPlayer", false)

func _ready() -> void:
	capture_mouse()
	
	
func _process(_delta) -> void:
	if Input.is_action_pressed("jump") and is_on_floor(): jumping = true
	if reorienting:
		camera.rotation.x -= 0.1
		if camera.rotation.x < -3:
			camera.rotation.x += 6
		if camera.rotation.x < 0.1 and camera.rotation.x > -0.1:
			reorienting = false
	if is_on_floor() and (camera.rotation.x < -1.5 or 
			camera.rotation.x > 1.5) and not reorienting:
		reorienting = true
	
	if Input.is_action_just_pressed("interact") and interact_scan.is_colliding() \
			and interact_scan.get_collider().has_method("interact"):
		interact_stream_player.play()
		interact_scan.get_collider().interact(self)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: 
			_rotate_camera(camera_zoom_sens)


func _physics_process(delta: float) -> void:
	if mouse_captured: _handle_joypad_camera_rotation(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta) + _knockback(delta)
	velocity.clamp(-max_speed, max_speed)
	move_and_slide()


func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


func _rotate_camera(sens_mod: float = 1.0) -> void:
#	print(camera.rotation)
	rotation.y -= look_dir.x * camera_sens * sens_mod
	if is_on_floor() and not reorienting:
		camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens 
				* sens_mod, -1.5, 1.5)
	else:
		camera.rotation.x -= look_dir.y * camera_sens * sens_mod


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
			deg_to_rad(move_dir.x * -roll_intensity), 
			delta * roll_speed
	)
	
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	
	if move_dir.length() == 0:
		sway_timer = PI/2 #smoothstep(sway_timer, PI/2, delta)
	else:
		sway_timer += delta
	
	# Handle camera & weapon sway/jump lag
	camera.position = Vector3(
			move_dir.length() * sway_height * cos(sway_speed * sway_timer), 
			0.5 + (move_dir.length() * sway_height/3 * sin(2 * sway_speed * sway_timer)), 
			0
	) if is_on_floor() else Vector3(
			0, 
			0.5 - clampf((grav_vel.y + jump_vel.y) * jump_sway, -0.1, 0.1),
			0
	)
	# Manipulating the v_offset like this makes it look like the weapon is moving relative to the camera
	camera.v_offset = move_dir.length() * -sway_height/6 * sin(10 * sway_timer) if \
			is_on_floor() else clampf((grav_vel.y + jump_vel.y) * jump_sway, -0.1, 0.1)
	
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
