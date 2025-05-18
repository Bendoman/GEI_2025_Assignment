extends Node3D

var world_grid
@export var radius: float = 1.0  # Radius or half-extent of the area
@onready var food_left_label = $FoodLeftLabel

var cylinder_mesh

var foodLeft
var entity

func _ready():
	world_grid = get_node("../WorldGrid") 
	world_grid.test()
	var pos = Vector3(global_position.x, 0, global_position.z)
	var cell = world_grid.position_to_cell(pos)
	entity = world_grid.register_entity(global_position, {"type": "foodsource", "position": pos, "foodLeft": 100, "cell": cell}, cell)
	
	# Create the cylinder mesh
	cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = world_grid.cell_size * 2
	cylinder_mesh.bottom_radius = world_grid.cell_size * 2
	cylinder_mesh.height = .5
	
	# Create the mesh instance and assign the mesh
	var mesh_instance_3d = MeshInstance3D.new()
	mesh_instance_3d.mesh = cylinder_mesh
	#mesh_instance_3d.translate(Vector3(0, 0.5, 0))  # Raise it so it sits on ground
	add_child(mesh_instance_3d)

	# Create and apply a 50% transparent green material
	var green_material := StandardMaterial3D.new()
	green_material.albedo_color = Color("#5fde6e97")  # Green with 50% alpha
	green_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	green_material.flags_transparent = true
	mesh_instance_3d.material_override = green_material


func _process(delta):
	if(entity.foodLeft != foodLeft):
		foodLeft = entity.foodLeft
		food_left_label.text = str(foodLeft)
		
		var scale_factor = foodLeft / 100.0
		cylinder_mesh.top_radius = radius * scale_factor
		cylinder_mesh.bottom_radius = radius * scale_factor
	
	if(entity.foodLeft <= 0):
		queue_free()
		
func register_to_grid(): 
	# Register all cells within radius, have system where debug meshes are drawn, 
	# entity has food value, when ants eat, check food value, if 0, free mesh, otherwise decrease alpha
	pass
