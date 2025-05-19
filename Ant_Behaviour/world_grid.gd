extends Node3D

var cell_size := .5
var grid := {}

var movement_cell_size := .2
var movement_grid := {} 

func printGrid():
	print_debug(JSON.stringify(grid, "\t"))

func position_to_movement_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floor(pos.x / movement_cell_size), floor(pos.z / movement_cell_size))

func position_to_cell(pos: Vector3) -> Vector2i: 
	return Vector2i(floor(pos.x / cell_size), floor(pos.z / cell_size))

func cell_to_position(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)

func get_entities_at_cell(cell: Vector2i) -> Array:
	if grid.has(cell):
		return grid[cell]
	return []

func register_entity(cell, entity):
	if not grid.has(cell):
		grid[cell] = [] 
	draw_debug_mesh_at_cell(cell, 1)
	
	grid[cell].append(entity)
	return grid[cell][grid[cell].size() - 1]


func unregister_entity(entity, cell):
	if(!grid.has(cell)): 
		return 
	
	for i in range(grid[cell].size() - 1, -1, -1): 
		var grid_entity = grid[cell][i]
		if(entity.type != grid_entity.type): 
			continue 
		
		if(entity.has("global_position") and entity.global_position == grid_entity.global_position):
			grid[cell].remove_at(i)
		elif(entity.type == "foodTrail" and entity.trail_index == grid_entity.trail_index):
			grid[cell].remove_at(i)
		elif(entity.type == "mesh_instance"):
			entity.instance.queue_free()
			grid[cell].remove_at(i)
		
	if(grid[cell].is_empty()):
		grid.erase(cell)

@export var debug_mesh: Mesh
@export var debug_material: Material  # Optional: can be null
@export var debug_scale: Vector3 = Vector3.ONE
@export var debug_height_offset: float = 0.0

func draw_debug_mesh_at_cell(cell: Vector2i, duration: float = 0.0) -> void:
	if debug_mesh == null:
		push_warning("No debug_mesh assigned!")
		return
	print(' in here')
	var instance := MeshInstance3D.new()
	instance.mesh = debug_mesh
	if debug_material:
		instance.material_override = debug_material

	var world_pos = cell_to_position(cell)
	instance.transform.origin = Vector3(
		world_pos.x + (cell_size / 2),
		debug_height_offset,
		world_pos.z + (cell_size / 2)
	)
	instance.scale = debug_scale

	add_child(instance)
	grid[cell].append({"type": "mesh_instance", "instance": instance})
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		unregister_entity(cell, {"type": "mesh_instance", "instance": instance})
