class_name WeaponManager extends Camera3D

@export_category("WeaponManager")

@export var weapons: Array[Array] = [[], [], [], [], [], [], []]
@export var current_category: int = 0
@export var current_index: Array[int] = [0, 0, 0, 0, 0, 0, 0]
#@export var current_weapon: int = 0

@export var ammo_types: Dictionary = {
	"none": 0,
	"shells": 50
}

var fov_desired

@onready var ammo_amounts: Dictionary = ammo_types.duplicate() # Created right before _ready
#@onready var gun_cam: Camera3D = find_child("GunCam")

signal switched_weapons(category: int, index: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	for key in ammo_amounts:
		ammo_amounts[key] = 0
	
	ammo_amounts["shells"] = 15
	
#	weapons[current_weapon].deploy
#	switched_weapons.connect(find_child("HUD")._on_player_cam_switched_weapons)
	switched_weapons.emit(current_category, current_index[current_category])
	fov_desired = fov


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	gun_cam.global_transform = global_transform
	
	if Input.is_action_just_pressed("next_weapon"):
		_next_weapon()
	if Input.is_action_just_pressed("previous_weapon"):
		_previous_weapon()
		
	if Input.is_action_just_pressed("weapon_1"):
		_select_category(0)
	if Input.is_action_just_pressed("weapon_2"):
		_select_category(1)
	if Input.is_action_just_pressed("weapon_3"):
		_select_category(2)
	if Input.is_action_just_pressed("weapon_4"):
		_select_category(3)
	if Input.is_action_just_pressed("weapon_5"):
		_select_category(4)
	if Input.is_action_just_pressed("weapon_6"):
		_select_category(5)
	if Input.is_action_just_pressed("weapon_7"):
		_select_category(6)
	
	if Input.is_action_just_pressed("debug_give_max_ammo"):
		for key in ammo_amounts:
			ammo_amounts[key] = ammo_types[key]


func _next_weapon():
#	weapons[current_weapon].holster
#	current_weapon += 1
	current_index[current_category] += 1
	while (not current_index[current_category] >= weapons[current_category].size()
			and weapons[current_category][current_index[current_category]] == null):
		current_index[current_category] += 1
	while current_index[current_category] >= weapons[current_category].size():
		current_index[current_category] -= 1
		current_category += 1
		if current_category >= weapons.size():
			current_category = 0
		
		while weapons[current_category].is_empty():
			current_category += 1
			if current_category >= weapons.size():
				current_category = 0
		
		current_index[current_category] = 0
		
		while weapons[current_category][current_index[current_category]] == null:
			current_index[current_category] += 1
	
	switched_weapons.emit(current_category, current_index[current_category])
	find_child("AudioStreamPlayer").playing = true
#	emit_signal("switched_weapons", 0, current_weapon)
#	weapons[current_weapon].deploy


func _previous_weapon():
#	weapons[current_weapon].holster
#	current_weapon -= 1
#	if current_weapon < 0:
#		current_weapon = weapons.size() - 1
	current_index[current_category] -= 1
	while (not current_index[current_category] < 0 and
			weapons[current_category][current_index[current_category]] == null):
		current_index[current_category] -= 1
	while current_index[current_category] < 0:
		current_index[current_category] += 1
		current_category -= 1
		if current_category >= weapons.size():
			current_category = 0
		
		while weapons[current_category].is_empty():
			current_category -= 1
			if current_category < 0:
				current_category = weapons.size() - 1
		
		current_index[current_category] = weapons[current_category].size() - 1
		
		while weapons[current_category][current_index[current_category]] == null:
			current_index[current_category] -= 1
	
	switched_weapons.emit(current_category, current_index[current_category])
	find_child("AudioStreamPlayer").play()


func _select_category(category: int):
	if current_category == category:
		current_index[category] += 1
		while (not current_index[category] >= weapons[category].size() and
				weapons[category][current_index[category]] == null):
			current_index[category] += 1
		if current_index[category] >= weapons[category].size():
			current_index[category] = 0
	else:
		current_category = category
	switched_weapons.emit(category, current_index[category])
	find_child("AudioStreamPlayer").play()


func has_ammo(type: String, amount: int = 1, virtual_charge: bool = false) -> bool:
#	print(ammo_amounts[type])
	if type == "none":
		return true
	if ammo_amounts[type] >= amount:
		if not virtual_charge:
			ammo_amounts[type] -= amount
		return true
	return false


func add_weapon(weapon: Node, starting_ammo: int = 0) -> bool:
	var weap: WeaponBase = weapon.get_child(0)
	if weapons[weap.category].is_empty() or weapons[weap.category].size() <= weap.index or (
			weapons[weap.category][weap.index] == null):
#			weapons[weap.category][weap.index] and not get_node(
#			weapons[weap.category][weap.index]).name == weapon.name):
		if weapons[weap.category].size() <= weap.index:
			weapons[weap.category].resize(weap.index + 1)
		weapons[weap.category][weap.index] = weapon
#		weapons[weap.category].pop_at(weap.index)
#		weapons[weap.category].insert(weap.index, weapon)
		current_category = weap.category
		current_index[weap.category] = weap.index
		switched_weapons.emit(weap.category, weap.index)
		find_child("AudioStreamPlayer").play()
		return true
	return false


func add_ammo(type: String, amount: int = 1) -> bool:
	if type != "none" and ammo_amounts[type] < ammo_types[type]:
		ammo_amounts[type] += amount
		return true
	return false


func force_add_ammo(type: String, amount: int = 1) -> void:
	if type != "none":
		ammo_amounts[type] += amount


func scope_changed(amount: float):
	fov = fov_desired / amount
	get_parent().camera_zoom_sens = 1 / amount
