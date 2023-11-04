extends Control

var current_ammo: String = "none"
var current_alt_ammo: String = "none"

@onready var status: PlayerStatus = get_parent().get_parent().find_child("Status")
@onready var manager: WeaponManager = get_parent()
@onready var health_counter: Label = find_child("HealthCounter")
@onready var ammo_counter: Label = find_child("AmmoCounter")
@onready var flash_rect: TextureRect = find_child("Flash")
@onready var blood_rect: TextureRect = find_child("Blood")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flash_rect.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	health_counter.text = "%s/%s%%" % [ceili(status.armor), ceili(status.health)]
	if status.health < 50:
		blood_rect.visible = true
		blood_rect.modulate.a = 1 - (status.health / 50)
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


func flash(color: Color) -> void:
	flash_rect.visible = true
	flash_rect.modulate = color


func flash_with_sound(color: Color, sound: AudioStream) -> void:
	flash(color)
	find_child("AudioStreamPlayer").stream = sound
	find_child("AudioStreamPlayer").play()


func _on_weapon_hud_connected(ammo_type: String, alt_ammo_type: String) -> void:
	current_ammo = ammo_type
	current_alt_ammo = alt_ammo_type
