extends EnemyBase

@export_category("EnemyLizard")

## The amount of time, in seconds, between when the melee attack animation
## begins and its associated projectile(s) actually spawn.
@export var melee_delay: float = 0.5
## The amount of time after spawning a melee attack's projectile(s) before this
## enemy can begin moving again.
@export var melee_recovery_time: float = 0.25
## The projectile(s) fired when this enemy performs a melee attack.
@export var melee_bullet: PackedScene
## The number of projectiles that should be fired per melee attack.
@export var melee_volley: int = 1
## The maximum horizontal offset of the melee attack's projectile(s), in degrees.
## Vertical spread is half this.
@export var melee_spread: float = 0.0

var attack_is_melee: bool = false

@onready var spawner_left: Node3D = find_child("SpawnerLeft")
@onready var spawner_right: Node3D = find_child("SpawnerRight")

func _attack(_delta) -> void:
	if state_timer >= attack_delay:
		if attack_is_melee:
			do_melee()
		else:
			do_attack()
	nav_agent.set_velocity(Vector3.ZERO)


func _begin_attack() -> void:
	attack_is_melee = (
			current_targets[-1].global_position.distance_squared_to(global_position)
			< melee_range_squared)
	look_at(current_targets[-1].position)
	rotation.x = 0
	state_machine.travel("meleeing" if attack_is_melee else "attacking", true)
	change_state(State.ATTACKING)


func do_attack() -> void:
#	var base_rotation = global_rotation
	if (not current_targets.is_empty()) and current_targets[-1] != null:
		spawner_left.look_at(current_targets[-1].global_position)
		spawner_right.look_at(current_targets[-1].global_position)
#	spawner.rotate_y(-PI)
#	spawner.rotate_x(PI)
	var spawner_l_base_rotation = spawner_left.global_rotation
	var spawner_r_base_rotation = spawner_right.global_rotation
	for v in volley:
		var s = spawner_right if 2 % (v + 1) == 0 else spawner_left

		s.global_rotation = (
				spawner_r_base_rotation if 2 % (v + 1) == 0
				else spawner_l_base_rotation
		)
		s.rotate_z(deg_to_rad(randf_range(-spread/2, spread/2)))
		spawner.rotate_y(deg_to_rad(randf_range(-spread/4, spread/4)))

		var instance = bullet.instantiate()
		if 2 % (v + 1) == 0:
			spawner_right.add_child(instance)
		else:
			spawner_left.add_child(instance)
		if instance is PhysicsBody3D:
			instance.add_collision_exception_with(self)
			add_collision_exception_with(instance)
		instance.reparent(get_tree().root)

		instance.invoker = self

#	global_rotation = spawner_base_rotation
	spawner_left.global_rotation = spawner_l_base_rotation
	spawner_right.global_rotation = spawner_r_base_rotation
	change_state(State.POST_ATTACKING)


func do_melee() -> void:
#	var base_rotation = global_rotation
	if (not current_targets.is_empty()) and current_targets[-1] != null:
		spawner.look_at(current_targets[-1].global_position)
#	spawner.rotate_y(-PI)
#	spawner.rotate_x(PI)
	var spawner_base_rotation = spawner.global_rotation
	for v in melee_volley:
		spawner.global_rotation = spawner_base_rotation
		spawner.rotate_z(deg_to_rad(randf_range(-spread/2, spread/2)))
		spawner.rotate_y(deg_to_rad(randf_range(-spread/4, spread/4)))

		var instance = melee_bullet.instantiate()
		spawner.add_child(instance)
		instance.reparent(get_tree().root)
		if instance is PhysicsBody3D:
			instance.add_collision_exception_with(self)
			add_collision_exception_with(instance)

		instance.invoker = self

#	global_rotation = spawner_base_rotation
	spawner.global_rotation = spawner_base_rotation
	change_state(State.POST_ATTACKING)
