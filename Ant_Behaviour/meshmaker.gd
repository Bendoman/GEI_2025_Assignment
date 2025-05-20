extends Node3D

@onready var body = $Body
@onready var mesh_instance_3d = $MeshInstance3D
@onready var mesh_instance_3d_2 = $MeshInstance3D2
@onready var mesh_instance_3d_3 = $MeshInstance3D3

func _ready():
	print("here")
	#var meshes = [abdomen, body, head, front_legs, middle_legs, back_legs]
	var meshes = [mesh_instance_3d, body, mesh_instance_3d_2, mesh_instance_3d_3]
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
			

	
	var save_path = "res://DeadAntMesh.tres"
	var result = ResourceSaver.save(combined_mesh, save_path)
	
	if result == OK:
		print("Saved combined mesh to: ", save_path)
	else:
		push_error("Failed to save combined mesh: ", result)
