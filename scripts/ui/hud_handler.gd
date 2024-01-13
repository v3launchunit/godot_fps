extends Control

@export var event_item: PackedScene
@export var alert_duration: float = 10

var current_ammo: String = "none"
var current_alt_ammo: String = "none"
var last_category: int = 1

var alert_timer: float = 0
var active_menus: int = 0

@onready var player: Player = get_parent().get_parent()
@onready var status: PlayerStatus = get_parent().get_parent().find_child("Status")
@onready var manager: WeaponManager = get_parent()

@onready var health_counter: Label = find_child("HealthCounter")
@onready var ammo_counter: Label = find_child("AmmoCounter")
@onready var flash_rect: TextureRect = find_child("Flash")
@onready var blood_rect: TextureRect = find_child("Blood")

@onready var keys: Array[Node] = $KeysContainer.get_children()
@onready var weapons: Array[Node] = $WeaponsContainer.get_children()
@onready var crosshairs: TextureRect = $Crosshairs
@onready var pause_menu: Control = $Menu
@onready var event_container: VBoxContainer = $EventContainer
@onready var alert: Label = $Alert

signal menu_closed(menu_layer: int)


func _ready() -> void:
	flash_rect.visible = false
	status.connect("key_acquired", _on_key_acquired)
#	pause_menu.reparent(get_tree().root)
#	get_tree().root.move_child(pause_menu, -1)


func _process(delta: float) -> void:
	health_counter.text = "%s/%s%%" % [ceili(status.armor), ceili(status.health)]
	if status.health < 50:
		blood_rect.visible = true
		blood_rect.modulate.a = clamp(1 - (status.health / 50), 0, 2)
	else:
		blood_rect.visible = false
	
	if current_alt_ammo == "none" or current_alt_ammo == current_ammo:
		if current_ammo == "none":
			ammo_counter.text = "--"
		else:
			ammo_counter.text = "%s" % manager.ammo_amounts[current_ammo]
	else:
		ammo_counter.text = "%s/%s" % [manager.ammo_amounts[current_ammo], 
				manager.ammo_amounts[current_alt_ammo]]
	
	if flash_rect.visible:
		flash_rect.modulate.a -= delta
		if flash_rect.modulate.a <= 0:
			flash_rect.visible = false
	
	if alert.visible:
		alert_timer -= delta
		if alert_timer <= 1.0:
			alert.modulate.a = alert_timer
		if alert_timer <= 0.0:
			alert.hide()
	
	if Input.is_action_just_pressed("ui_cancel"):
		if active_menus <= 0:
			get_tree().paused = true
			pause_menu.show()
			player.release_mouse()
			active_menus = 1
		else:
			close_top_menu()
	
	if Input.is_action_just_pressed("quick_exit"): 
		get_tree().quit()


func close_top_menu() -> void:
	menu_closed.emit(active_menus)
	active_menus -= 1
	if active_menus <= 0:
		get_tree().paused = false
		pause_menu.hide()
		player.capture_mouse()
		active_menus = 0


func flash(color: Color) -> void:
	flash_rect.visible = true
	flash_rect.modulate = color


func flash_with_sound(color: Color, sound: AudioStream) -> void:
	flash(color)
	find_child("AudioStreamPlayer").stream = sound
	find_child("AudioStreamPlayer").play()


func log_event(event_text) -> void:
	var event: Label = event_item.instantiate()
	event.text = event_text
	event_container.add_child(event)
	event_container.move_child(event, 0)


func set_alert(alert_text: String) -> void:
	alert.text = alert_text
	alert.modulate.a = 1.0
	alert.show()
	alert_timer = alert_duration


func _on_weapon_hud_connected(category: int, index: int, ammo_type: String, \
		alt_ammo_type: String) -> void:
	current_ammo = ammo_type
	current_alt_ammo = alt_ammo_type
	crosshairs.texture.region.position = Vector2(index * 32, category * 32)
	weapons[last_category].self_modulate = Color(0.5, 0.5, 0.5)
	weapons[category].visible = true
	weapons[category].self_modulate = Color(1, 1, 1)
	weapons[category].texture.region.position.x = index * 32
	weapons[category].get_child(0).texture.region.position.x = index * 32
	last_category = category


func _on_key_acquired(key: int) -> void:
	keys[key].modulate = Color.WHITE
