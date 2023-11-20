class_name Status extends Node

@export_category("Status")

signal injured(source: Node3D)
signal died

@export var max_health: float = 100.0
@export var gib_threshold: float = 50.0
@export var damage_sys: PackedScene
@export_file("*.tscn") var gibs: String
@export var loot: Array[PackedScene] = []

var health: float
var is_dead: bool = false
#var overheal_decay_rate: float = 1 # hp/second

@onready var gibs_scene: PackedScene = load(gibs)

# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health
#	if get_parent().has_signal("body_entered"):
#		get_parent().body_entered.connect(damage)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	if health > max_health:
#		health -= overheal_decay_rate * delta
#		if health < max_health:
#			health = max_health


func damage(amount: float) -> float:
	health -= amount
#	print(health)
	if damage_sys != null:
		var instance := damage_sys.instantiate()
		get_parent().add_child(instance)
	if health <= -gib_threshold:
		if not is_dead:
			kill()
		
		get_parent().queue_free()
		var exp: Node
		if gibs_scene != null:
			print("gibbed")
			exp = gibs_scene.instantiate()
			get_parent().add_child(exp)
			exp.reparent(get_tree().root)
			gibs_scene = null
		return 0	
	if is_dead:
		return 0 # corpses cannot stop piercers
	if health <= 0:
		kill()
		return maxf(amount + health, 0) # health will be negative
	injured.emit()
	
	return amount # return value is amount of damage recieved, for piercers


func heal(amount: float, can_overheal: bool = false, heal_armor: bool = false) -> bool:
	if not heal_armor and (health < max_health or can_overheal):
		health += amount
		return true
	return false


func kill():
	is_dead = true
	died.emit()
#	print("this thing is fucking dead!")
	if not loot.is_empty():
		var loot_spawn: RigidBody3D = loot.pick_random().instantiate()
		get_parent().add_child(loot_spawn)
		loot_spawn.reparent(get_tree().root)
		loot_spawn.rotation = Vector3(0, 0, 0)
		loot_spawn.linear_velocity = Vector3(randf_range(-3, 3), 10, randf_range(-3, 3))
		
#		var loot_scene = load(loot.pick_random())
