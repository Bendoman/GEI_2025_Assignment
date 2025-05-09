extends Node3D

@onready var abdomen = $Abdomen
@onready var head = $Head
@onready var front_legs = $Front_Legs
@onready var middle_legs = $Middle_Legs
@onready var back_legs = $Back_Legs
@onready var body = $Body

func _ready():
	var meshes = [abdomen, body, head, front_legs, middle_legs, back_legs]
	var combined_mesh := ArrayMesh.new()

	for mesh_instance in meshes: 
		var mesh = mesh_instance.mesh
		var transform = mesh_instance.transform 
		
		for surface_index in mesh.get_surface_count():
			var arrays = mesh.surface_get_arrays(surface_index).duplicate(true)
			var vertices = arrays[Mesh.ARRAY_VERTEX]
			var normals = arrays[Mesh.ARRAY_NORMAL]
			
			for i in range(vertices.size()):
				vertices[i] = transform * vertices[i]
			
			for i in range(normals.size()):
				normals[i] = (transform.basis * normals[i]).normalized()
			
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals 
			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			

	#for mesh_instance in meshes:
		#if not mesh_instance or not mesh_instance.mesh:
			#continue
		#var mesh = mesh_instance.mesh
		#for surface_index in mesh.get_surface_count():
			#var arrays = mesh.surface_get_arrays(surface_index)
			#combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


	
	var save_path = "res://CombinedAntMesh.tres"
	var result = ResourceSaver.save(combined_mesh, save_path)
	
	if result == OK:
		print("Saved combined mesh to: ", save_path)
	else:
		push_error("Failed to save combined mesh: ", result)
