extends VBoxContainer

@onready var res_x: LineEdit = find_child("ResolutionX")
@onready var res_y: LineEdit = find_child("ResolutionY")

@onready var fov_slider: HSlider = find_child("FovSlider")
@onready var fov_label: Label = find_child("FovLabel")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass # Replace with function body.


func _on_resolution_apply_button_pressed() -> void:
	if not res_x.text.is_valid_int():
		res_x.text = ProjectSettings.get_setting("display/window/size/viewport_width")
		return
	
	if not res_y.text.is_valid_int():
		res_y.text = ProjectSettings.get_setting("display/window/size/viewport_height")
		return
	
	ProjectSettings.set_setting("display/window/size/viewport_width", res_x)
	ProjectSettings.set_setting("display/window/size/viewport_height", res_y)


func _on_scale_slider_value_changed(value: float) -> void:
	ProjectSettings.set_setting("display/window/stretch/scale", value)


func _on_fov_slider_value_changed(value: float) -> void:
	Globals.s_fov_desired = value
	fov_label.text = "%s" % value
