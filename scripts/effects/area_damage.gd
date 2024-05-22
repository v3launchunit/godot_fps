class_name AreaDamage
extends Area3D

@export_category("AreaDamage")

@export var damage: float = 120
@export var player_damage_override: float = 30
@export var damage_type: Status.DamageType = Status.DamageType.GENERIC
@export var knockback_force: float = 15

var invoker: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_area_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_body_entered(body: Node3D) -> void:
	if body.has_node("Status"):
		body.find_child("Status").damage(
				player_damage_override
				if body.find_child("Status") is PlayerStatus
				else damage
		)
		if body != null and body is EnemyBase and body != invoker:
			body.detect_target(invoker)
	if body.has_method("apply_knockback"):
		body.apply_knockback(knockback_force * (
				body.global_position - global_position
		).normalized())
