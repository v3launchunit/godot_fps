@tool
extends StaticBody3D


const TRASH_LIST : Array[String] = [
		"res://objects/deco/trash/trash_bag.tscn",
		"res://objects/deco/trash/trash_pole.tscn",
		"res://objects/deco/trash/trash_brick.tscn",
		"res://objects/deco/trash/trash_brick.tscn",
		"res://objects/deco/trash/trash_brick.tscn",
		"res://scenes/objects/crate_metal.tscn",
]

@export var func_godot_properties: Dictionary:
	set(to):
		func_godot_properties = to
		spawn_trash_props()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#spawn_trash_props(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func spawn_trash_props(editor: bool = true) -> void:
	if editor and not Engine.is_editor_hint():
		return
	
	collision_layer = 0b0000_0000_0000_0000_0000_0010_0000_0000
	
	var mesh := (get_child(0) as MeshInstance3D).mesh
	var shape := mesh.create_convex_shape(false)
	var points := shape.points
	var bounds := mesh.get_aabb().abs()
	var volume : float = bounds.get_volume()
	
	var point_query := PhysicsPointQueryParameters3D.new()
	point_query.collide_with_bodies = true
	point_query.collide_with_areas = false
	point_query.collision_mask = 0b0000_0000_0000_0000_0000_0010_0000_0000
	
	for i in range(roundi(volume * func_godot_properties["prop_density"])):
		var pos := position + Vector3(
				randf_range(bounds.position.x, bounds.end.x), 
				randf_range(bounds.position.y, bounds.end.y), 
				randf_range(bounds.position.z, bounds.end.z),
		)
		var space_state := get_world_3d().direct_space_state
		point_query.position = pos
		var result := space_state.intersect_point(point_query, 1)
		
		if result == null or result.is_empty():
			continue
		
		var node := (load(TRASH_LIST.pick_random()) as PackedScene).instantiate() as Node3D
		add_child(node)
		node.set_owner(owner)
		node.global_position = pos
		node.rotation = Vector3(
				randf_range(-PI, PI), 
				randf_range(-PI, PI), 
				randf_range(-PI, PI),
		)
	
	collision_layer = 0b0000_0000_0000_0000_0000_0000_0000_0001
