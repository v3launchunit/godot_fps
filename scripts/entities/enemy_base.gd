class_name EnemyBase extends CharacterBody3D

enum State {
	IDLE, # Does not have a target
	SEARCHING, # Moving towards detected sound and does not have a target
	PURSUING, # Pursuing target
	ATTACKING, # Firing at target
	POST_ATTACKING, # Recovering after firing at target
	FLINCHING, # Unable to move due to flinching from an attack
	DEAD, # But not gibbed
}

@export_category("EnemyBase")
@export_range(1, 35, 1) var speed: float = 10 # walk speed, in meters/second
@export var turning_speed: float = 10
@export_range(10, 400, 1) var acceleration: float = 100
@export var knockback_drag: float = 10 # How much my knockback velocity decreases each second

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1

@export_range(0, 360, 1, "radians") var sight_line_sweep_angle: float = PI / 2
@export_range(0, 10) var sight_line_sweep_speed: float = 3 # how many sweeps I do in PI seconds

@export var attack_interval: float = 3.0 # How many seconds I spend moving between attacks
@export var attack_range: float = 32.0 # Max distance at which I will attack
@export var attack_delay: float = 0.5 # How many seconds into my attack animation do I actually fire
@export var attack_recovery_time: float = 0.25 # How long do I wait after firing before I go back to moving
@export_file("*.tscn") var bullet: String
@export var volley: int = 1
@export var spread: float = 0

@export_range(0, 1) var flinch_chance: float = 0.1
@export var flinch_time: float = 1.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_state: State = State.IDLE
var current_target: PhysicsBody3D
var current_destination: Vector3

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity
var knockback_vel: Vector3 # Knockback velocity

var state_timer: float = 0 # How long I've been in my current state, in seconds

@onready var nav_agent: NavigationAgent3D = find_child("NavigationAgent3D")
@onready var sight_line: RayCast3D = find_child("SightLine")
@onready var status: Status = find_child("Status")

@onready var spawner: Node3D = find_child("Spawner")
@onready var bullet_scene: PackedScene = load(bullet)
@onready var state_machine = $AnimationTree.get("parameters/playback")

func _ready() -> void:
	state_machine.start("idle", true)
	status.injured.connect(_on_status_injured)
	status.died.connect(_on_status_died)


func _process(delta: float) -> void:
	state_timer += delta

func _physics_process(delta: float) -> void:
	velocity = _gravity(delta) + _knockback(delta)

	match current_state:
		State.IDLE:
			_scan()
		State.SEARCHING:
			_investigate(delta)
			_scan()
		State.PURSUING:
			_pursue(delta)
		State.ATTACKING:
			_attack()
		State.POST_ATTACKING:
			_post_attack()
		State.FLINCHING:
			_flinch()
		State.DEAD:
			pass
	
	move_and_slide()


# In case I need/want to do stuff with state transitions 
# (probably where I'll handle animations & shit)
func change_state(to: State):
	match current_state:
		State.IDLE:
			sight_line.rotation.y = 0
		State.SEARCHING:
			sight_line.rotation.y = 0
		State.PURSUING:
			pass
		State.ATTACKING:
			pass
		State.POST_ATTACKING:
			pass
		State.FLINCHING:
			pass
		State.DEAD:
			pass
	
	match to:
		State.IDLE:
			sight_line.rotation.x = 0
			state_machine.travel("idle", true)
		State.SEARCHING:
			sight_line.rotation.x = 0
			state_machine.travel("moving", true)
		State.PURSUING:
			state_machine.travel("moving", true)
		State.ATTACKING:
			state_machine.travel("attacking", true)
		State.POST_ATTACKING:
			pass
		State.FLINCHING:
			state_machine.travel("flinching", true)
		State.DEAD:
			state_machine.travel("dead", true)
	
	current_state = to
	state_timer = 0


func _scan() -> void:
	sight_line.rotation.y = sin(state_timer * sight_line_sweep_speed / 
			sight_line_sweep_angle * 2) * sight_line_sweep_angle / 2
	if sight_line.is_colliding() and sight_line.get_collider() is Player:
		current_target = sight_line.get_collider()
		change_state(State.PURSUING)


func _investigate(delta) -> void:
	nav_agent.target_position = current_destination
#	look_at(nav_agent.get_next_path_position())
#	rotation.x = 0
	global_rotation.y = lerp_angle(global_rotation.y, 
			sight_line.global_rotation.y, delta * turning_speed)
	walk_vel = walk_vel.move_toward(-speed * transform.basis.z, acceleration * delta)
	velocity += walk_vel
	if nav_agent.is_target_reached():
		change_state(State.IDLE)


func _pursue(delta) -> void:
#	# Check if I can actually still see my target, otherwise go to its last known position
#	# (Basically, this is to prevent omniscient AI in the laziest way possible)
#	sight_line.look_at(current_target.global_position)
#	if sight_line.get_collider() != current_target:
#		current_destination = current_target.global_position
#		change_state(State.SEARCHING)
#		return
	
	# Actually approach target
	nav_agent.target_position = current_target.global_position
	var next_pos := nav_agent.get_next_path_position()
	sight_line.look_at(next_pos)
	global_rotation.y = lerp_angle(global_rotation.y, 
			sight_line.global_rotation.y, delta * turning_speed)
	walk_vel = walk_vel.move_toward(-speed * transform.basis.z, acceleration * delta)
	velocity += walk_vel
	
	# Decide if it's time to attack my target
	if state_timer >= attack_interval and \
			current_target.global_position.distance_to(global_position) < attack_range: #and sight_line.get_collider() == current_target:
		look_at(current_target.position)
		rotation.x = 0
		change_state(State.ATTACKING)


func _attack() -> void:
	if state_timer >= attack_delay:
#		var base_rotation = global_rotation
		spawner.look_at(current_target.global_position)
#		spawner.rotate_y(-PI)
#		spawner.rotate_x(PI)
		var spawner_base_rotation = spawner.global_rotation
		for v in volley:
			spawner.global_rotation = spawner_base_rotation
			spawner.rotate_z(deg_to_rad(randf_range(-spread/2, spread/2)))
			spawner.rotate_y(deg_to_rad(randf_range(-spread/4, spread/4)))
			
			var instance = bullet_scene.instantiate()
			spawner.add_child(instance)
			instance.reparent(get_tree().root)
			if instance is PhysicsBody3D:
				instance.add_collision_exception_with(self)
				add_collision_exception_with(instance)
			
			instance.invoker = self
			
#		global_rotation = spawner_base_rotation
		spawner.global_rotation = spawner_base_rotation
		change_state(State.POST_ATTACKING)


func _post_attack() -> void:
	if state_timer >= attack_recovery_time:
		change_state(State.IDLE if current_target == null else State.PURSUING)


func _flinch() -> void:
	if state_timer >= flinch_time:
		change_state(State.PURSUING)


func _do_jump() -> void:
	if is_on_floor():
		jump_vel.y = jump_height


func apply_knockback(amount: Vector3) -> void:
	if amount.y < 0:
		jump_vel = Vector3.ZERO
		grav_vel = Vector3.ZERO
#		jumping = false
	knockback_vel += amount


func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(
			Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel


func _knockback(delta: float) -> Vector3:
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, knockback_drag * delta)
	return knockback_vel


func _on_status_injured() -> void:
	if randf() < flinch_chance:
		change_state(State.FLINCHING)
	else:
		change_state(State.PURSUING)


func _on_status_died() -> void:
	change_state(State.DEAD)
