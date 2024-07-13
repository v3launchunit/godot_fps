extends Label

@onready var level := get_tree().current_scene as Level

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = "%s\n%02d:%02d:%02.3f\n%02d%02d%02.3f\n%03d\n%03d\n%03d,%03d,%03d,%02d0" % [
			level.level_name, # name
			level.time / 3600.0, # process hours
			level.time / 60.0, # process minutes
			level.time, # process seconds/milliseconds
			level.physics_time / 3600.0, # physics hours
			level.physics_time / 60.0, # physics minutes
			level.physics_time, # physics seconds/milliseconds
			level.kills, # enemies killed
			level.secrets, # secrets found
			(level.score / 100_000_000) % 1000, # total score, first 3 digits
			(level.score / 100_000) % 1000, # total score, next 3 digits
			(level.score / 100) % 1000, # total score, following 3 digits
			level.score % 100, # total score, last 2 digits + bonus 0
	]
