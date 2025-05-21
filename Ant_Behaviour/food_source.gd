extends Node3D

var world_grid

@onready var food_left_label = $FoodLeftLabel



var foodLeft
var entity
var radius

var cylinder_mesh
var mesh_instance_3d

var pickable_object

func _ready():
	print("ready in here")
	world_grid = get_node("../../WorldGrid") 
	pickable_object = get_node("../PickableObject") 
	print(world_grid)
	print(pickable_object)
	init()
	

func init(): 
	foodLeft = 100
	food_left_label.text = str(foodLeft)
	
	if(mesh_instance_3d != null):
		remove_child(mesh_instance_3d)
	
	var pos = Vector3(global_position.x, 0, global_position.z)
	var cell = world_grid.position_to_cell(pos)
	entity = world_grid.register_entity(global_position, {"type": "foodsource", "position": pos, "foodLeft": 100, "cell": cell}, cell)
	
	# Create the cylinder mesh
	radius = world_grid.cell_size * 1.5
	cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = .5
	
	# Create the mesh instance and assign the mesh
	mesh_instance_3d = MeshInstance3D.new()
	mesh_instance_3d.mesh = cylinder_mesh
	# Create and apply a 50% yellow material
	var green_material := StandardMaterial3D.new()
	green_material.albedo_color = Color("#FFE60010")  # 50% transparent yellow
	green_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	green_material.flags_transparent = true
	mesh_instance_3d.material_override = green_material
	
	add_child(mesh_instance_3d)



func _process(delta):
	if(Global.stopped): 
		position = Vector3(pickable_object.position.x, position.y, pickable_object.position.z)
	
	if(entity.foodLeft != foodLeft):
		foodLeft = entity.foodLeft
		food_left_label.text = str(foodLeft)
		
		var scale_factor = foodLeft / 100.0
		cylinder_mesh.top_radius = radius * scale_factor
		
		cylinder_mesh.bottom_radius = radius * scale_factor
	
	#if(entity.foodLeft <= 0):
		#queue_free()
		
func register_to_grid(): 
	# Register all cells within radius, have system where debug meshes are drawn, 
	# entity has food value, when ants eat, check food value, if 0, free mesh, otherwise decrease alpha
	pass
