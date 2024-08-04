class_name AreaSecret
extends Area3D


@export var properties: Dictionary

@onready var level := get_tree().current_scene as Level


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if level and not level.loaded_from_savegame:
		level.secrets += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_body_entered(body: Node3D) -> void:
	if level and body is Player:
		level.found_secrets += 1
		var hud := (body as Player).hud
		
		hud.set_alert("YOU FOUND A SECRET!\n%0*d/%s" % [
				ceili(log(level.secrets)) / log(10), 
				level.found_secrets, 
				level.secrets,
		])
	
	queue_free()
