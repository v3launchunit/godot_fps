extends Node

## This script is meant to hold various constants, global variables, user
## settings, etc. It also handles saving and loading user settings to and from
## the disc, but it's not really meant to perform any real logic beyond that.


# ---------------------------------------------------------------------------- #
# --------------------------------- CONSTANTS -------------------------------- #
# ---------------------------------------------------------------------------- #

## Error value for float equality comparisons (direct equality comparisons are
## inadvisable because of floating-point precision errors resulting in numbers
## potentially being slightly off).
const C_EPSILON: float = 0.0001
## The percentage chance that a given enemy will check if it should re-evaluate
## its current path on a given frame (to prevent lag spikes from everyone
## recalculating their paths simultaneously).
const C_PATH_RE_EVAL_CHANCE: float = 0.1


# ---------------------------------------------------------------------------- #
# --------------------------------- SETTINGS --------------------------------- #
# ---------------------------------------------------------------------------- #

## The screen's resolution is divided by this. Does not affect UI.
var s_stretch_scale: int = 2
## The screen's resolution is divided by this. Only affects UI.
var s_ui_scale: float = 1.0
## Self-explanatory.
var s_crosshair_size: float = 1.0

## The base vertical Field of View for the player's camera.
var s_fov_desired: float = 120
## Ditto. but for viewmodels (high fov causes viewmodels to look stretched out
## and generally ugly).
var s_viewmodel_fov: float = 90

## Toggles the procedural halos created by the "glow" post-processing effect.
var s_glow_enabled: bool = true
## Toggles the mesh-based halos present on various light sources and
## bright objects.
var s_flares_enabled: bool = true
## Toggles a procedural cross-shaped lens flare post-processing effect. I worked
## very hard on it.
var s_cross_glow_enabled: bool = false

## The sensitivity multiplier applied to mouse movement with regards to the
## first-person camera.
var s_camera_sensitivity: float = 12

## Self-explanatory.
var s_master_volume: float = 87
## Self-explanatory.
var s_sound_volume: float = 100
## Self-explanatory.
var s_music_volume: float = 100

## Tells scripts to check to see if the game's settings have been changed and
## to update any values they need to.
signal settings_changed


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_config()


func _ready() -> void:
	settings_changed.connect(_on_settings_changed)


func _load_config() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg") # Read from file.
	if err != OK:
		return # If the file didn't load, ignore it.

	s_stretch_scale = config.get_value("video", "stretch_scale", s_stretch_scale)
	s_ui_scale = config.get_value("video", "ui_scale", s_ui_scale)
	s_crosshair_size = config.get_value("video", "crosshair_size", s_crosshair_size)
	s_fov_desired = config.get_value("video", "fov_desired", s_fov_desired)
	s_viewmodel_fov = config.get_value("video", "viewmodel_fov", s_viewmodel_fov)
	s_flares_enabled = config.get_value("video", "flares_enabled", s_flares_enabled)
	s_glow_enabled = config.get_value("video", "glow_enabled", s_glow_enabled)
	s_cross_glow_enabled = config.get_value("video", "cross_glow_enabled", s_cross_glow_enabled)

	s_master_volume = config.get_value("audio", "master_volume", s_master_volume)
	s_sound_volume = config.get_value("audio", "sound_volume", s_sound_volume)
	s_music_volume = config.get_value("audio", "music_volume", s_music_volume)


func _on_settings_changed() -> void:
	var config = ConfigFile.new()

	config.set_value("video", "stretch_scale", s_stretch_scale)
	config.set_value("video", "ui_scale", s_ui_scale)
	config.set_value("video", "crosshair_size", s_crosshair_size)
	config.set_value("video", "fov_desired", s_fov_desired)
	config.set_value("video", "viewmodel_fov", s_viewmodel_fov)
	config.set_value("video", "flares_enabled", s_flares_enabled)
	config.set_value("video", "glow_enabled", s_glow_enabled)
	config.set_value("video", "cross_glow_enabled", s_cross_glow_enabled)

	config.set_value("audio", "master_volume", s_master_volume)
	config.set_value("audio", "sound_volume", s_sound_volume)
	config.set_value("audio", "music_volume", s_music_volume)

	config.save("user://settings.cfg") # Write to file.
