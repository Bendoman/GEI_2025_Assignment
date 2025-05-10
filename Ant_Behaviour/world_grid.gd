extends Node3D

var cell_size := 0.1
var grid := {}

func test():
	print('test')

func position_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floor(pos.x / cell_size), floor(pos.z / cell_size))

func cell_to_position(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)


func register_entity(pos: Vector3, entity):
	var cell := position_to_cell(pos)
	
	if not grid.has(cell):
		grid[cell] = [] 
	
	grid[cell].append(entity)
	print(grid)
	
	draw_debug_mesh_at_cell(cell)
	#print(pos, cell)
	
func unregister_entity(pos: Vector3, entity) -> void:
	var cell = position_to_cell(pos)
	if not grid.has(cell):
		return

	for i in range(grid[cell].size()):
		var entry = grid[cell][i]
		if entry.type == entity.type:
			grid[cell].remove_at(i)


	if grid[cell].is_empty():
		grid.erase(cell)


@export var debug_mesh: Mesh
@export var debug_material: Material  # Optional: can be null
@export var debug_scale: Vector3 = Vector3.ONE
@export var debug_height_offset: float = 0.0

func draw_debug_mesh_at_cell(cell: Vector2i, duration: float = 0.0) -> void:
	if debug_mesh == null:
		push_warning("No debug_mesh assigned!")
		return

	var instance := MeshInstance3D.new()
	instance.mesh = debug_mesh
	if debug_material:
		instance.material_override = debug_material

	var world_pos = cell_to_position(cell)
	print(world_pos)
	instance.transform.origin = Vector3(
		world_pos.x + (cell_size / 2),
		debug_height_offset,
		world_pos.z + (cell_size / 2)
	)
	instance.scale = debug_scale

	add_child(instance)
	#grid[cell].append({"type": "mesh_instance", "instance": instance})
	#print(grid)
	

	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		instance.queue_free()
