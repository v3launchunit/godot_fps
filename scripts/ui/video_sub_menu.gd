extends VBoxContainer

@onready var fov_slider: HSlider = find_child("FovSlider")
@onready var fov_label: Label = find_child("FovLabel")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_fov_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Globals.s_fov_desired = fov_slider.value
		fov_label.text = "%s" % fov_slider.value
