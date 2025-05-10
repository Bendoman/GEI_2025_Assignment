extends Node3D

var world_grid

func _ready():
	world_grid = get_node("../WorldGrid") 
	world_grid.test()
	world_grid.register_entity(global_position, {"type": "foodsource"})
	print(world_grid.grid)
