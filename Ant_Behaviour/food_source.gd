extends Node3D

var world_grid
@export var radius: float = 1.0  # Radius or half-extent of the area

@onready var mesh_instance_3d = $MeshInstance3D.mesh as CylinderMesh

func _ready():
	world_grid = get_node("../WorldGrid") 
	world_grid.test()
	world_grid.register_entity(global_position, {"type": "foodsource", "position": global_position})
	print(world_grid.grid)
	
	mesh_instance_3d.top_radius = radius
	mesh_instance_3d.bottom_radius = radius

func register_to_grid(): 
	# Register all cells within radius, have system where debug meshes are drawn, 
	# entity has food value, when ants eat, check food value, if 0, free mesh, otherwise decrease alpha
	pass
