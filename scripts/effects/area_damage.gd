extends Area3D

@export_category("AreaDamage")

@export var damage: float = 60
@export var knockback: float = 15

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_area_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_body_entered(body: Node3D) -> void:
	if body.has_node("Status"):
		body.find_child("Status").damage(damage)
	if body.has_method("apply_knockback"):
		body.apply_knockback(knockback * (body.global_position - global_position).normalized())
