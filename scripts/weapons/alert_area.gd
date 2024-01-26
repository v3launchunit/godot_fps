extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass


func on_body_entered(body: Node3D) -> void:
#	print("sound heard")
	if body.has_method("detect_target") and (
			body.current_targets.is_empty()
			or body.current_targets[-1] != find_parent("Player")
	):
		body.detect_target(find_parent("Player"))
#		print("target updated to " + get_node(^"../../../..").name)
#	print(body is EnemyBase)
#	if body is EnemyBase:
#		print(body.current_targets.is_empty())
#		print(body.current_targets[-1] if not body.current_targets.is_empty() else \
#				"no targets lol")
