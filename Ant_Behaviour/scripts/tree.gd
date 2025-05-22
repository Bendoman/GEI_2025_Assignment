extends Node3D
@onready var model = $Model

var world_grid
func _ready(): 
	world_grid = get_node("../../WorldGrid")	
	# Rotate model randomly around Y axis (in radians)
	var random_angle = randf_range(0.0, TAU)  # TAU = 2π
	model.rotation.y = random_angle
	
func register(): 
	var cell = world_grid.position_to_cell(global_position)
	world_grid.register_entity(global_position, {
			"cell": cell,
			"type": "obstacle", 
			"global_position": global_position
		}, cell)
