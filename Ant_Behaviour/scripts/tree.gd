extends Node3D

var world_grid
func _ready(): 
	world_grid = get_node("../../WorldGrid")	

func register(): 
	var cell = world_grid.position_to_cell(global_position)
	world_grid.register_entity(global_position, {
			"cell": cell,
			"type": "obstacle", 
			"global_position": global_position
		}, cell)
