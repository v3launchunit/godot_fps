class_name Status extends Node

signal injured(source: Node3D)
signal died

enum DamageType {
	GENERIC,
	EXPLOSION,
	FIRE,
	TOXIC,
	ELECTRIC,
}

@export_category("Status")

## The amount of health this node will have when initialized, and the maximum
## amount of health it can be healed to (besides bonus health).
@export var max_health: float = 100.0
## The amount of additional damage after death required to cause this node's
## parent to explode into its gibs.
@export var gib_threshold: float = 50.0
@export var base_damage_factor: float = 1.0
@export var damage_multipliers: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]
## The scene that instantiates whenever this node takes damage.
@export var damage_sys: PackedScene
## The scene that instantiates if this node's parent is reduced to gibs.
@export var gibs: PackedScene
@export var gibs_offset: Vector3 = Vector3.ZERO
## One of the contained scenes will be randomly selected to be instantiated
## when this node's parent dies.
@export var loot: Array[PackedScene] = []
## How far up the tree this node should affect its parents.
@export var ripple_distance: int = 1

@export_group("Save Data")
@export var health: float
@export var is_dead: bool = false
@export var target_parent: Node
#var overheal_decay_rate: float = 1 # hp/second

#@onready var gibs_scene: PackedScene = load(gibs)

# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health
	target_parent = get_parent()
	for i in (ripple_distance - 1):
		target_parent = target_parent.get_parent()
#	if get_parent().has_signal("body_entered"):
#		get_parent().body_entered.connect(damage)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	if health > max_health:
#		health -= overheal_decay_rate * delta
#		if health < max_health:
#			health = max_health


func damage(amount: float) -> float:
	return damage_typed(amount, DamageType.GENERIC)


func damage_typed(amount: float, type: DamageType) -> float:
	health -= amount * base_damage_factor * damage_multipliers[type]
#	print(health)
	if damage_sys != null:
		var instance := damage_sys.instantiate()
		target_parent.add_child(instance)
	if health <= -gib_threshold:
		if not is_dead:
			kill()

		target_parent.queue_free()
		var i: Node3D
		if gibs != null:
			print("gibbed")
			i = gibs.instantiate() as Node3D
			target_parent.add_child(i)
			i.translate(gibs_offset)
			i.reparent(get_tree().current_scene)
			gibs = null
		return 0
	if is_dead:
		return 0 # corpses cannot stop piercers
	if health <= 0:
		kill()
		return maxf(amount + health, 0) # health will be negative
	injured.emit()

	return amount # return value is amount of damage recieved, for piercers


func rapid_damage(amount: float) -> void:
	rapid_damage_typed(amount, DamageType.GENERIC)


func rapid_damage_typed(amount: float, type: DamageType) -> void:
	damage_typed(amount, type)


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
		target_parent.add_child(loot_spawn)
		loot_spawn.reparent(get_tree().root.get_child(2))
		loot_spawn.rotation = Vector3(0, 0, 0)
		loot_spawn.linear_velocity = Vector3(randf_range(-3, 3), 10, randf_range(-3, 3))

#		var loot_scene = load(loot.pick_random())
