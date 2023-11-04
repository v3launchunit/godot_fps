extends RigidBody3D

@export_category("Projectile Bullet")

@export_range(-100, 100, 1) var speed: float = 10
@export var damage: float = 10
@export_file("*.tscn") var explosion: String
@export var sticky: bool = false
@export var piercer: bool = true

var invoker: Node3D

@onready var explosion_scene: PackedScene = load(explosion)

# Called when the node enters the scene tree for the first time.
func _ready():
	linear_velocity = speed * global_transform.basis.z.normalized()
#	add_collision_exception_with(get_node("Player"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if piercer and linear_velocity != speed * global_transform.basis.z.normalized():
		linear_velocity = speed * global_transform.basis.z.normalized()
#	if body_entered:
#		print("bullet collided")
#		queue_free()


func _on_body_entered(body: Node):
	var exp: Node
	if explosion_scene != null:
		exp = explosion_scene.instantiate()
		add_child(exp)
		exp.reparent(get_tree().root)
#	if sticky:
#		exp.reparent(body)
	
	if body.has_node("Status"):
		damage -= body.find_child("Status").damage(damage)
		if body is EnemyBase:
			body.current_target = invoker
		if not piercer or damage <= 0:
			queue_free()
		else:
			add_collision_exception_with(body)
			linear_velocity = speed * global_transform.basis.z.normalized()
	else:
		queue_free()
