extends Node3D

var world_grid

func _ready(): 
	world_grid = get_node("../../WorldGrid")	
	print("tree grid ", world_grid)
	
func register(): 
	var cell = world_grid.position_to_cell(global_position)
	world_grid.register_entity(global_position, {
			"type": "obstacle", 
			"global_position": global_position
		}, cell)
	print("Registering")
	
	world_grid.printGrid()
