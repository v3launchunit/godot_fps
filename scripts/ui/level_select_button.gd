extends Button

## The scene to load when this button is pressed.
@export var _scene: PackedScene
@export var level_name: String
@export var always_open: bool = false
@export var is_secret: bool = false

@onready var _press_sound: AudioStreamPlayer = GameMenu.get_node(^"ButtonPress")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if _scene == null or not (
			always_open 
			or Globals.level_revealed(level_name)
			or OS.has_feature("editor")
	):
		disabled = true
		if is_secret:
			visible = false
	pressed.connect(_on_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Player.mouse_captured:
		Player.release_mouse()


func check_unlocked() -> void:
	if _scene != null and Globals.level_revealed(level_name):
		disabled = false
		if is_secret:
			visible = true


func _on_pressed() -> void:
	_press_sound.play()
	Globals.open_level(_scene)
