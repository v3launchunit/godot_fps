class_name WeaponBase extends Node3D

#signal recoiled(amount: Vector3)
signal hud_connected(category: int, index: int, ammo_type: String, alt_ammo_type: String)

@export_category("Weapon")

@export_range(0, 6, 1) var category: int = 0
@export var index: int = 0

@export_file("*.tscn") var bullet: String
@export_range(0, 3, 0.01) var shot_cooldown: float = 1.0 # seconds
@export_range(1, 50, 1) var volley: int = 1
@export_range(0, 90) var spread: float = 0.0
@export var recoil: float = 0.0

@export var ammo_type: String = "none"
@export var ammo_cost: int = 1
@export var use_safety_catch: bool = true

@export var anti_clip_distance: float = 0

var active: bool = true
var cooldown_timer: float = 0.0 # seconds
var refire_penalty: float = 0.0
var safety_catch_active: bool = false

@onready var spawner = find_child("Spawner")
@onready var bullet_scene: PackedScene = load(bullet)
@onready var state_machine = $AnimationTree.get("parameters/playback")
@onready var manager: WeaponManager = get_parent().get_parent()
@onready var eject_sys: GPUParticles3D = find_child("ShellEject")
#@onready var alert_area: Area3D = get_node_or_null("AlertRadius")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	bullet_scene = load(bullet)
	manager.switched_weapons.connect(_on_player_cam_switched_weapons)
	hud_connected.connect(manager.find_child("HUD")._on_weapon_hud_connected)
#	hud_connected.emit(ammo_type, "none")
#	recoiled.connect(p.get_parent().get_script().apply_knockback)
	state_machine.start("deploy", true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if refire_penalty > 0:
		refire_penalty -= delta
	
	if (
			active and 
			(not safety_catch_active) and 
			Input.is_action_pressed("weapon_fire_main") and 
			cooldown_timer <= 0 and 
			manager.has_ammo(ammo_type, ammo_cost)
	):
		_fire()
	
	if safety_catch_active and not Input.is_action_pressed("weapon_fire_main"):
		safety_catch_active = false


#func _unhandled_input(_event: InputEvent) -> void:


func _on_player_cam_switched_weapons(c, i, catch) -> void:
	if c == category and i == index:
		_deploy(catch)
	else:
		_holster()


func _deploy(with_safety_catch: bool = true) -> void:
	visible = true
	active = true
	safety_catch_active = use_safety_catch if with_safety_catch else false
	hud_connected.emit(category, index, ammo_type, "none")
	state_machine.start("deploy", true)


func _holster() -> void:
	visible = false
	active = false


func _fire() -> void:
	var base_rotation = global_rotation
	var spawner_base_rotation = spawner.global_rotation
	for v in volley:
#		if manager.find_child("RayCast3D").is_colliding():
#			spawner.look_at(manager.find_child("RayCast3D").get_collision_point())
#			spawner.rotate_y(PI)
#		else:
		global_rotation = base_rotation
		spawner.global_rotation = spawner_base_rotation
		rotate_y(deg_to_rad(randf_range(-spread/2, spread/2) * refire_penalty))
		rotate_x(deg_to_rad(randf_range(-spread/4, spread/4) * refire_penalty))
		refire_penalty = 1.0
		
		var instance = bullet_scene.instantiate()
		spawner.add_child(instance)
		instance.reparent(get_tree().root)
		instance.invoker = manager.get_parent_node_3d()
		
	global_rotation = base_rotation
	spawner.global_rotation = spawner_base_rotation
	
	if recoil != 0:
#		recoiled.emit(Vector3.BACK * recoil)
		var p: Player = find_parent("Player")
		p.apply_knockback(recoil * get_global_transform().basis.z * -1)
	
	cooldown_timer = shot_cooldown
	if eject_sys != null:
		eject_sys.emit_particle(eject_sys.transform, transform.basis.z * Vector3.LEFT, \
				Color.WHITE, Color.WHITE, 0)
	state_machine.start("firing", true)
	#instance.AddCollisionExceptionWith(get_parent().get_parent())
