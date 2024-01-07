extends Control


func _on_video_button_pressed() -> void:
	pass # Replace with function body.


func _on_audio_button_pressed() -> void:
	pass # Replace with function body.


func _on_gameplay_button_pressed() -> void:
	pass # Replace with function body.


func _on_input_button_pressed() -> void:
	pass # Replace with function body.


func _on_accessibility_button_pressed() -> void:
	pass # Replace with function body.


func _on_other_button_pressed() -> void:
	pass # Replace with function body.


func _on_back_button_pressed() -> void:
	find_parent("HUD").close_top_menu()
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED


func _on_hud_menu_closed(menu_layer) -> void:
	if menu_layer == 2:
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED
