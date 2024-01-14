extends Node

# Constants
const C_PATH_RE_EVAL_CHANCE: float = 0.1 # Percentage chance that a given enemy 
		# re-evaluates its current path on a given frame (to prevent lag spikes 
		# from everyone doing it at once)

# Settings
var s_fov_desired: float = 120 # Base FOV
