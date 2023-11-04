extends WeaponBase

@export_category("AltFire")

@export_file("*.tscn") var alt_bullet: String
@export_range(0, 3, 0.05) var alt_shot_cooldown: float = 1.0 # seconds
@export_range(1, 50, 1) var alt_volley: int = 1
@export_range(0, 90, 1) var alt_spread: float = 0.0

@export var alt_ammo_type: String = "none"
@export var alt_ammo_cost: int = 1

@onready var alt_spawner = get_node("AltSpawner")
@onready var alt_bullet_scene: PackedScene = load(alt_bullet)

# Called when the node enters the scene tree for the first time.
func _ready():
#	var p = get_parent().get_parent()
	manager.switched_weapons.connect(_on_player_cam_switched_weapons)
	hud_connected.connect(manager.find_child("HUD")._on_weapon_hud_connected)
	hud_connected.emit(ammo_type, alt_ammo_type)
	state_machine.start("deploy", true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if (active and Input.is_action_pressed("fire_main") and cooldown_timer <= 0
			and manager.has_ammo(ammo_type, ammo_cost)):
		_fire()
		
	if (active and Input.is_action_pressed("fire_alt") and cooldown_timer <= 0
			and manager.has_ammo(alt_ammo_type, alt_ammo_cost)):
		_fire_alt()


func _deploy() -> void:
	visible = true
	active = true
	hud_connected.emit(ammo_type, alt_ammo_type)
	state_machine.start("deploy", true)


func _fire_alt():
	var base_rotation = alt_spawner.rotation
	for v in alt_volley:
#		if manager.find_child("RayCast3D").is_colliding():
#			alt_spawner.look_at(manager.find_child("RayCast3D").get_collision_point())
#			alt_spawner.rotate_y(PI)
#		else:
		alt_spawner.rotation = base_rotation
		alt_spawner.rotate_y(deg_to_rad(randf_range(-alt_spread/2, alt_spread/2)))
		alt_spawner.rotate_x(deg_to_rad(randf_range(-alt_spread/4, alt_spread/4)))
		
		var instance = alt_bullet_scene.instantiate()
		alt_spawner.add_child(instance)
		instance.reparent(get_tree().root)
		instance.invoker = manager.get_parent_node_3d()
	
	alt_spawner.rotation = base_rotation
	
	cooldown_timer = alt_shot_cooldown
	state_machine.start("alt_firing", true)
