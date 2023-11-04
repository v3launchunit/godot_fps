class_name PlayerStatus extends Status

@export_category("Player Status")

@export var max_armor: float = 100
@export_range(0, 1, 0.01) var armor_absorption := 0.5

var armor: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = max_health
	armor = max_armor / 4


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	if health > max_health:
#		health -= overheal_decay_rate * delta
#		if health < max_health:
#			health = max_health


func damage(amount: float) -> float: # returns damage dealt, for piercers
	health -= amount * (1 - armor_absorption)
	armor  -= amount * armor_absorption
	if armor <= 0:
		health += armor # armor will be negative
		armor = 0
#	print(health)
	if health <= -gib_threshold:
		if not is_dead:
			kill()
		
#		get_parent().queue_free()
		var exp: Node
		if gibs_scene != null:
			exp = gibs_scene.instantiate()
			get_parent().add_child(exp)
			exp.reparent(get_tree().root)
			gibs_scene = null
		return 0
	if is_dead:
		return 0 # corpses cannot stop piercers
	if health <= 0:
		kill()
		return amount + health # health will be negative
	return amount # return value is amount of damage recieved, for piercers


func heal(amount: float, can_overheal: bool = false, heal_armor: bool = false) -> bool:
	if not heal_armor and (health < max_health or can_overheal):
		health += amount
		return true
	if heal_armor and (armor < max_armor or can_overheal):
		armor += amount
		return true
	return false

