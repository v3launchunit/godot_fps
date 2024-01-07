class_name EnemyBase extends CharacterBody3D

enum State {
	AMBUSHING, # Busy spawning in and can't do anything
	IDLE, # Does not have a target
	SEARCHING, # Moving towards detected sound and does not have a target
	PURSUING, # Pursuing target
	ATTACKING, # Firing at target
	POST_ATTACKING, # Recovering after firing at target
	FLINCHING, # Unable to move due to flinching from an attack
	DEAD, # But not gibbed
}

@export_category("EnemyBase")
@export_range(1, 35, 0.1) var speed: float = 10.0 # walk speed, in meters/second
@export var turning_speed: float = 10.0
@export_range(10, 400, 1) var acceleration: float = 100.0
@export_range(0, 1, 0.001, "or_greater") var knockback_multiplier: float = 1.0
@export var knockback_drag: float = 10.0 # How much my knockback velocity decreases each second

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1

@export_range(0, 360, 1, "radians") var sight_line_sweep_angle: float = PI / 2
@export_range(0, 10, 0.1, "or_greater") var sight_line_sweep_speed: float = 3 # how many sweeps I do in PI seconds
#@export var enemies: Array[String] = ["Player"]
@export var detection_stream: AudioStream

@export var wake_up_time: float = 3.0 # How many seconds does it take for me to spawn in
@export var attack_interval: float = 3.0 # How many seconds I spend moving between attacks
@export var attack_range: float = 32.0 # Max distance at which I will attack
@export var melee_range: float = 2.0 # Distance at which I don't need to move between attacks
@export var attack_delay: float = 0.5 # How many seconds into my attack animation do I actually fire
@export var attack_recovery_time: float = 0.25 # How long do I wait after firing before I go back to moving
@export_file("*.tscn") var bullet: String
@export var volley: int = 1
@export var spread: float = 0.0

@export_range(0, 1) var flinch_chance: float = 0.1
@export var flinch_time: float = 1.0
@export var death_stream: AudioStream

@export var current_targets: Array[PhysicsBody3D]

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_state: State = State.AMBUSHING
var current_destination: Vector3

var walk_vel: Vector3 = Vector3.ZERO # Walking velocity 
var safe_walk_vel: Vector3 = Vector3.ZERO
var grav_vel: Vector3 = Vector3.ZERO # Gravity velocity 
var jump_vel: Vector3 = Vector3.ZERO # Jumping velocity
var knockback_vel: Vector3 = Vector3.ZERO # Knockback velocity

var state_timer: float = 0 # How long I've been in my current state, in seconds

@onready var nav_agent: NavigationAgent3D = find_child("NavigationAgent3D")
@onready var sight_line: RayCast3D = find_child("SightLine")
@onready var status: Status = find_child("Status")

@onready var spawner: Node3D = find_child("Spawner")
@onready var bullet_scene: PackedScene = load(bullet)
@onready var state_machine = $AnimationTree.get("parameters/playback")
@onready var attack_range_squared = attack_range * attack_range
@onready var melee_range_squared = melee_range * melee_range
@onready var path_re_eval_distance_squared = $NavigationAgent3D.target_desired_distance \
		* $NavigationAgent3D.target_desired_distance

@onready var audio_player: AudioStreamPlayer3D = find_child("AudioStreamPlayer3D")

func _ready() -> void:
	state_machine.start("ambush", true)
	status.injured.connect(_on_status_injured)
	status.died.connect(_on_status_died)
	nav_agent.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)


func _process(delta: float) -> void:
	state_timer += delta


func _physics_process(delta: float) -> void:
	velocity = _gravity(delta) + _knockback(delta)

	match current_state:
		State.AMBUSHING:
			if state_timer >= wake_up_time:
				change_state(State.IDLE)
		State.IDLE:
			_scan(delta)
		State.SEARCHING:
			_investigate(delta)
			_scan(delta)
		State.PURSUING:
			_pursue(delta)
		State.ATTACKING:
			_attack(delta)
		State.POST_ATTACKING:
			_post_attack(delta)
		State.FLINCHING:
			_flinch()
		State.DEAD:
			pass
	
	if check_target_validity() and current_targets[-1].get_node("Status").health <= 0:
		current_targets.pop_back()
	
	move_and_slide()


# In case I need/want to do stuff with state transitions 
# (probably where I'll handle animations & shit)
func change_state(to: State):
	if current_state == State.DEAD or to == current_state:
		return
	
	match current_state:
		State.AMBUSHING:
			pass
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
		State.AMBUSHING:
			pass
		State.IDLE:
			sight_line.rotation.x = 0
			state_machine.travel("idle", true)
		State.SEARCHING:
			sight_line.rotation.x = 0
			state_machine.travel("moving", true)
		State.PURSUING:
			if check_target_validity():
				nav_agent.target_position = current_targets[-1].global_position
			state_machine.travel("moving", true)
		State.ATTACKING:
			pass
		State.POST_ATTACKING:
			pass
		State.FLINCHING:
			state_machine.travel("flinching", true)
		State.DEAD:
			audio_player.stream = death_stream
			audio_player.play()
			state_machine.travel("dead", true)
	
	walk_vel = Vector3.ZERO
	nav_agent.set_velocity(Vector3.ZERO)
	current_state = to
	state_timer = 0


func detect_target(target: PhysicsBody3D) -> void:
	if not (
			current_state == State.AMBUSHING 
			or current_state == State.FLINCHING 
			or current_state == State.DEAD
	):
		if current_targets.is_empty():
			audio_player.stream = detection_stream
			audio_player.play()
		current_targets.append(target)
#	print("target detected")
		if current_state == State.IDLE or current_state == State.SEARCHING:
			change_state(State.PURSUING)


func _scan(_delta) -> void:
	sight_line.rotation.y = sin(state_timer * sight_line_sweep_speed + randf() / 
			sight_line_sweep_angle * 2) * sight_line_sweep_angle / 2
	if sight_line.is_colliding() and sight_line.get_collider() is Player:
		detect_target(sight_line.get_collider())
		change_state(State.PURSUING)
	nav_agent.set_velocity(Vector3.ZERO)


func _investigate(delta) -> void:
	if randf() < Globals.C_PATH_RE_EVAL_CHANCE:
		nav_agent.target_position = current_destination
#	look_at(nav_agent.get_next_path_position())
#	rotation.x = 0
	global_rotation.y = lerp_angle(global_rotation.y, 
			sight_line.global_rotation.y, delta * turning_speed)
	walk_vel = walk_vel.move_toward(-speed * transform.basis.z, acceleration * delta)
#	velocity += walk_vel
	nav_agent.set_velocity(walk_vel)
	velocity += safe_walk_vel
	if nav_agent.is_target_reached():
		change_state(State.IDLE)


func _pursue(delta) -> void:
	# [Removed because it makes them look stupid]
	# Check if I can actually still see my target, otherwise go to its last known position
	# (Basically, this is to prevent omniscient AI in the laziest way possible)
#	sight_line.look_at(current_target.global_position)
#	if sight_line.get_collider() != current_target:
#		current_destination = current_target.global_position
#		change_state(State.SEARCHING)
#		return
	
	# Casually approach target
	if check_target_validity(): # Make sure I actually have a target first
		if check_path_staleness():
			nav_agent.target_position = current_targets[-1].global_position
		var next_pos := nav_agent.get_next_path_position()
		sight_line.look_at(next_pos)
		global_rotation.y = (
				lerp_angle(global_rotation.y, 
				sight_line.global_rotation.y, delta * turning_speed)
		)
		walk_vel = walk_vel.move_toward(-speed * transform.basis.z, acceleration * delta)
		nav_agent.set_velocity(walk_vel)
#		velocity += safe_walk_vel
		
		# Decide if it's time to attack my target
		if check_attack_readiness():
			_begin_attack()
		
	else: # Can't pursue a target that doesn't exist
		change_state(State.IDLE)
		# Scrapped conditionals to try and make enemies breach obstacles 
		# (might reimplement later idk)
# 				\
#				or (sight_line.get_collider().global_position.distance_to(global_position) < 2 \
#				and sight_line.get_collider().find_child("Status") != null) 


func check_target_validity() -> bool:
	return not (current_targets.is_empty() or current_targets[-1] == null)


func check_path_staleness() -> bool:
	return (
			randf() < Globals.C_PATH_RE_EVAL_CHANCE 
			and nav_agent.target_position.distance_squared_to(
			current_targets[-1].global_position) > path_re_eval_distance_squared
		)


func check_attack_readiness() -> bool:
	return (
			current_targets[-1].global_position.distance_squared_to(global_position) 
			< melee_range_squared or (
					state_timer >= attack_interval + randf() 
					and current_targets[-1].global_position.distance_squared_to(global_position)
					< attack_range_squared
			)
		) #and sight_line.get_collider() == current_target:


func _begin_attack() -> void:
	look_at(current_targets[-1].position)
	rotation.x = 0
	state_machine.travel("attacking", true)
	change_state(State.ATTACKING)


func _attack(_delta) -> void:
	if state_timer >= attack_delay:
		do_attack()
	nav_agent.set_velocity(Vector3.ZERO)


func do_attack() -> void:
#	var base_rotation = global_rotation
	if (not current_targets.is_empty()) and current_targets[-1] != null:
		spawner.look_at(current_targets[-1].global_position)
#	spawner.rotate_y(-PI)
#	spawner.rotate_x(PI)
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
		
#	global_rotation = spawner_base_rotation
	spawner.global_rotation = spawner_base_rotation
	change_state(State.POST_ATTACKING)


func _post_attack(_delta) -> void:
	if state_timer >= attack_recovery_time:
		change_state(
				State.IDLE if current_targets.is_empty() or 
				current_targets[-1] == null or 
				current_targets[-1].find_child("Status").health <= 0 else State.PURSUING
		)
	nav_agent.set_velocity(Vector3.ZERO)


func _flinch() -> void:
	if state_timer >= flinch_time:
		change_state(State.PURSUING)
	nav_agent.set_velocity(Vector3.ZERO)


func _do_jump() -> void:
	if is_on_floor():
		jump_vel.y = jump_height


func apply_knockback(amount: Vector3) -> void:
	if amount.y < 0:
		jump_vel = Vector3.ZERO
		grav_vel = Vector3.ZERO
#		jumping = false
	knockback_vel += amount * knockback_multiplier


func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(
			Vector3(0, velocity.y - gravity, 0), gravity * delta
	)
	return grav_vel


func _knockback(delta: float) -> Vector3:
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, knockback_drag * delta)
	return knockback_vel


func _on_status_injured() -> void:
	if randf() < flinch_chance:
		change_state(State.FLINCHING)
	elif current_state == State.IDLE:
		change_state(State.PURSUING)


func _on_status_died() -> void:
	change_state(State.DEAD)


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity += safe_velocity
	move_and_slide()
