class_name Level
extends Node3D

@export var level_id := Vector2i(1, 1)
@export var level_name: String = "LEVEL"

@export_group("Save Data")
@export var level_version: String = "PENDING"
@export var time: float = 0.0
@export var physics_time: float = 0.0
@export var kills: int = 0
@export var foes: int = 0 ## total number of tallied foes in the level.
@export var found_secrets: int = 0
@export var secrets: int = 0 ## total number of secrets in the level.
@export var score: int = 0
@export var loaded_from_savegame: bool = false
@export var fun: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if level_version == "PENDING":
		level_version = Globals.C_VERSION
	if fun == -1:
		fun = Globals.fun


func _process(delta: float) -> void:
	time += delta


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	physics_time += delta
