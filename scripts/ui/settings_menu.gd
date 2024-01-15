extends Control

enum SubMenus {
	VIDEO,
	AUDIO,
	GAMEPLAY,
	INPUT,
	ACCESSIBILITY,
	OTHER
}

var current_sub_menu: SubMenus = SubMenus.VIDEO


func _on_video_button_pressed() -> void:
	_select_sub_menu(SubMenus.VIDEO)


func _on_audio_button_pressed() -> void:
	_select_sub_menu(SubMenus.AUDIO)


func _on_gameplay_button_pressed() -> void:
	_select_sub_menu(SubMenus.GAMEPLAY)


func _on_input_button_pressed() -> void:
	_select_sub_menu(SubMenus.INPUT)


func _on_accessibility_button_pressed() -> void:
	_select_sub_menu(SubMenus.ACCESSIBILITY)


func _on_other_button_pressed() -> void:
	_select_sub_menu(SubMenus.OTHER)


func _select_sub_menu(sub_menu: SubMenus) -> void:
	$SettingsPanel.get_child(current_sub_menu).process_mode = Node.PROCESS_MODE_DISABLED
	$SettingsPanel.get_child(current_sub_menu).hide()
#	match sub_menu:
#		SubMenus.VIDEO:
#			pass
#		SubMenus.AUDIO:
#			pass
#		SubMenus.GAMEPLAY:
#			pass
#		SubMenus.INPUT:
#			pass
#		SubMenus.ACCESSIBILITY:
#			pass
#		SubMenus.OTHER:
#			pass
	current_sub_menu = sub_menu
	$SettingsPanel.get_child(sub_menu).process_mode = Node.PROCESS_MODE_INHERIT
	$SettingsPanel.get_child(sub_menu).show()


func _on_back_button_pressed() -> void:
	find_parent("GameMenu").close_top_menu()
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED


func _on_menu_closed(menu_layer: int) -> void:
	if menu_layer == 2:
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED
