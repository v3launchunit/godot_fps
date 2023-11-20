extends EnemyBase

@export var target_distance: float = 5.0

@onready var floor_line: RayCast3D = find_child("FloorLine")

func _scan(delta) -> void:
	sight_line.rotation.y = sin(state_timer * sight_line_sweep_speed / 
			sight_line_sweep_angle * 2) * sight_line_sweep_angle / 2
	sight_line.rotation.x = cos(state_timer * sight_line_sweep_speed / 
			sight_line_sweep_angle * PI) * sight_line_sweep_angle / 2
	
	if sight_line.is_colliding() and sight_line.get_collider() is Player:
		detect_target(sight_line.get_collider())
		change_state(State.PURSUING)
	
	walk_vel = walk_vel.move_toward(Vector3.ZERO, acceleration * delta)
	nav_agent.set_velocity(walk_vel)


func _pursue(delta) -> void:
	# Casually approach target
	if current_target != null: # Make sure I actually have a target first
		nav_agent.target_position = current_target.global_position
		var next_pos := nav_agent.get_next_path_position()
		sight_line.look_at(next_pos)
		global_rotation = lerp(global_rotation, 
				sight_line.global_rotation, delta * turning_speed)
		walk_vel = walk_vel.move_toward(-speed * sight_line.global_transform.basis.z, \
					acceleration * delta)
		
		if floor_line.is_colliding():
			walk_vel.y += jump_height
		
		if global_position.distance_to(current_target.global_position) < target_distance:
			walk_vel += jump_height * sight_line.global_transform.basis.z
		
		nav_agent.set_velocity(walk_vel)
#		velocity += walk_vel
		
		# Decide if it's time to attack my target
		if current_target.global_position.distance_to(global_position) < 2 or \
				state_timer >= attack_interval + randf() and \
				current_target.global_position.distance_to(global_position) < attack_range: #and sight_line.get_collider() == current_target:
			change_state(State.ATTACKING)
	else: # Can't pursue a target that doesn't exist
		change_state(State.IDLE)


func _attack(delta) -> void:
	look_at(current_target.global_position)
	walk_vel = walk_vel.move_toward(Vector3.ZERO, acceleration * delta)
	nav_agent.set_velocity(walk_vel)
	if state_timer >= attack_delay:
		do_attack()


#func _post_attack(delta) -> void:
#	walk_vel = walk_vel.move_toward(Vector3.ZERO, acceleration * delta)
#	nav_agent.set_velocity(walk_vel)


func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() or current_state != State.DEAD \
			else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	
	return grav_vel


#func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
#	pass
