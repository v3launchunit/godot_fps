extends VBoxContainer

@onready var res_x: LineEdit = find_child("ResolutionX")
@onready var res_y: LineEdit = find_child("ResolutionY")

@onready var scale_slider: HSlider = find_child("ScaleSlider")
@onready var scale_label: Label = find_child("ScaleLabel")

@onready var ui_scale_slider: HSlider = find_child("UIScaleSlider")
@onready var ui_scale_label: Label = find_child("UIScaleLabel")

@onready var crosshair_size_slider: HSlider = find_child("CrosshairSizeSlider")
@onready var crosshair_size_label: Label = find_child("CrosshairSizeLabel")

@onready var fov_slider: HSlider = find_child("FovSlider")
@onready var fov_label: Label = find_child("FovLabel")

@onready var flares_check: CheckButton = find_child("FlaresCheck")
@onready var bloom_check: CheckButton = find_child("BloomCheck")
@onready var cbloom_check: CheckButton = find_child("CBloomCheck")


func _ready() -> void:
	scale_slider.set_value_no_signal(Globals.s_stretch_scale)
	scale_label.text = "%sx" % Globals.s_stretch_scale
	ui_scale_slider.set_value_no_signal(Globals.s_ui_scale)
	ui_scale_label.text = "%sx" % Globals.s_ui_scale
	fov_slider.set_value_no_signal(Globals.s_fov_desired)
	fov_label.text = "%s" % Globals.s_fov_desired
	flares_check.set_pressed_no_signal(Globals.s_flares_enabled)
	bloom_check.set_pressed_no_signal(Globals.s_glow_enabled)
	cbloom_check.set_pressed_no_signal(Globals.s_cross_glow_enabled)


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
	Globals.s_stretch_scale = floori(value)
	scale_label.text = "%sx" % value


#func _on_scale_slider_drag_ended(value_changed: bool) -> void:
	#pass


func _on_ui_scale_slider_value_changed(value: float) -> void:
	ProjectSettings.set_setting("display/window/stretch/scale", value)
	Globals.s_ui_scale = value
	ui_scale_label.text = "%sx" % value


func _on_ui_scale_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		get_tree().root.content_scale_factor = Globals.s_ui_scale


func _on_crosshair_size_slider_value_changed(value: float) -> void:
	Globals.s_crosshair_size = value
	crosshair_size_label.text = "%sx" % value


func _on_fov_slider_value_changed(value: float) -> void:
	Globals.s_fov_desired = value
	fov_label.text = "%s" % value


func _on_flares_check_toggled(button_pressed: bool) -> void:
	Globals.s_flares_enabled = button_pressed


func _on_bloom_check_toggled(button_pressed: bool) -> void:
	Globals.s_glow_enabled = button_pressed


func _on_c_bloom_check_toggled(button_pressed: bool) -> void:
	Globals.s_cross_glow_enabled = button_pressed
