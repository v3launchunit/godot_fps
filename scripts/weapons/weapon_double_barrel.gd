class_name WeaponDoubleBarrel extends WeaponBase

var from_alt_barrel: bool = false

@onready var alt_spawner = find_child("AltSpawner")

func _fire() -> void:
#	var base_rotation = global_rotation
#	var spawner_base_rotation = alt_spawner.global_rotation if from_alt_barrel \
#			else spawner.global_rotation
	for v in volley:
#		global_rotation = base_rotation
#		spawner.global_rotation = spawner_base_rotation
#		alt_spawner.global_rotation = spawner_base_rotation
#		rotate_y(deg_to_rad(randf_range(-spread/2, spread/2)))
#		rotate_x(deg_to_rad(randf_range(-spread/4, spread/4)))
		
		var instance = bullet_scene.instantiate()
		if from_alt_barrel:
			alt_spawner.add_child(instance)
		else:
			spawner.add_child(instance)
		instance.reparent(get_tree().root)
#		get_tree().root.add_child(instance)
#		instance.position = alt_spawner.global_position if from_alt_barrel \
#				else spawner.global_position
#		instance.rotation = alt_spawner.global_rotation if from_alt_barrel \
#				else spawner.global_rotation
		instance.invoker = manager.get_parent_node_3d()
		from_alt_barrel = not from_alt_barrel
	
#	global_rotation = base_rotation
#	spawner.global_rotation = spawner_base_rotation
#	alt_spawner.global_rotation = spawner_base_rotation
	
	if recoil != 0:
		var p: Player = find_parent("Player")
		p.apply_knockback(recoil * get_global_transform().basis.z * -1)
	
	cooldown_timer = shot_cooldown
	if eject_sys != null:
		eject_sys.emit_particle(eject_sys.transform, transform.basis.z * Vector3.LEFT, \
				Color.WHITE, Color.WHITE, 0)
	state_machine.start("alt_firing" if from_alt_barrel else "firing", true)
