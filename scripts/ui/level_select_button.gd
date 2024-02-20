extends Button

## The scene to load when this button is pressed.
@export var _scene: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Player.mouse_captured:
		Player.release_mouse()


func _on_pressed() -> void:
	get_tree().change_scene_to_packed(_scene)
