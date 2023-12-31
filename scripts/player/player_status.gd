class_name PlayerStatus extends Status

@export_category("Player Status")

@export var max_armor: float = 100
@export_range(0, 1, 0.01) var armor_absorption := 0.5

var armor: float
var held_keys: Array[bool] = [false, false, false]

signal key_acquired(key: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = max_health
	armor = max_armor / 4
	target_parent = get_parent()
	for i in (ripple_distance - 1):
		target_parent = target_parent.get_parent()
	key_acquired.connect(_on_key_acquired)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_give_max_health"):
		health = 100 if health < 100 else health
		armor = 25 if armor < 25 else armor
		is_dead = false
		
	if Input.is_action_just_pressed("debug_give_max_armor"):
		armor = 100 if armor < 100 else armor
#	if health > max_health:
#		health -= overheal_decay_rate * delta
#		if health < max_health:
#			health = max_health


func damage(amount: float) -> float: # returns damage dealt, for piercers
	if is_dead:
		return 0 # corpses cannot stop piercers
	get_parent().find_child("HUD").flash(Color(1, 0, 0, clamp(amount / 10, 0.1, 1)))
	health -= amount * (1 - armor_absorption)
	armor  -= amount * armor_absorption
	if armor <= 0:
		health += armor # armor will be negative
		armor = 0
	if health <= 0:
		kill()
		return amount + health # health will be negative
	return amount # return value is amount of damage recieved, for piercers


func kill():
	is_dead = true
	died.emit()
	get_parent().process_mode = Node.PROCESS_MODE_DISABLED
	if gibs_scene != null:
		var exp: Node = gibs_scene.instantiate()
		target_parent.add_child(exp)
		exp.reparent(get_tree().root)
		get_parent().find_child("PlayerCam").current = false
		gibs_scene = null


func heal(amount: float, can_overheal: bool = false, heal_armor: bool = false) -> bool:
	if not heal_armor and (health < max_health or can_overheal):
		health += amount
		return true
	if heal_armor and (armor < max_armor or can_overheal):
		armor += amount
		return true
	return false


func _on_key_acquired(key: int):
	held_keys[key] = true
