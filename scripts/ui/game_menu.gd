extends Control

var _active_menus: int = 0

@onready var _level_select_menu: Control = $LevelSelect
@onready var _settings_menu: Control = $Settings
#@onready var player: Player = get_tree().root.find_child("Player")

signal menu_closed(menu_layer: int)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if _active_menus <= 0:
			get_tree().paused = true
			show()
			Player.release_mouse()
			_active_menus = 1
		else:
			close_top_menu()


func close_top_menu() -> void:
	menu_closed.emit(_active_menus)
	_active_menus -= 1
	if _active_menus <= 0:
		get_tree().paused = false
		hide()
		Player.capture_mouse()
		_active_menus = 0


func _on_campaign_button_pressed() -> void:
	_level_select_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_level_select_menu.show()
	_active_menus = 2


func _on_save_button_pressed() -> void:
	pass # Replace with function body.


#func _on_load_button_pressed() -> void:
#	pass # Replace with function body.


func _on_settings_button_pressed() -> void:
	_settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_menu.show()
	_active_menus = 2


func _on_quit_button_pressed() -> void:
	get_tree().quit()
