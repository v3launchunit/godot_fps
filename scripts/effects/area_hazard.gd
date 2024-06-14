class_name AreaHazard
extends Area3D

@export var properties: Dictionary

@export var dps: float = 1.0
@export var player_dps_override: float = 1.0
@export var damage_type: Status.DamageType = Status.DamageType.GENERIC


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if properties:
		dps = properties["dps"]
		player_dps_override = properties["player_dps"]
		damage_type = Status.DamageType[properties["damage_type"]]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.has_node("Status"):
			body.get_node("Status").rapid_damage_typed(dps, damage_type, delta)
