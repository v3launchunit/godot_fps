extends Control

@onready var settings_menu: Control = find_child("Settings")


func _on_campaign_button_pressed() -> void:
	pass # Replace with function body.


func _on_save_button_pressed() -> void:
	pass # Replace with function body.


func _on_load_button_pressed() -> void:
	pass # Replace with function body.


func _on_settings_button_pressed() -> void:
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_menu.show()
	get_parent().active_menus += 1


func _on_quit_button_pressed() -> void:
	get_tree().quit()
