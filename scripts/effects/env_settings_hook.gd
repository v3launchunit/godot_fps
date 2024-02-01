extends WorldEnvironment


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.settings_changed.connect(_on_globals_settings_changed)
	_on_globals_settings_changed()


func _on_globals_settings_changed() -> void:
	environment.glow_enabled = Globals.s_glow_enabled
