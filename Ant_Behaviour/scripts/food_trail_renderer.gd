extends MultiMeshInstance3D
#
#var instance_count
#@onready var ant_renderer = $"../AntRenderer"
#
#var trail_nodes = []
#
#func _ready():
	#await get_tree().process_frame
	#instance_count = ant_renderer.instance_count
#
	#var sphere := SphereMesh.new()
	#sphere.radius = 0.05
	#sphere.height = 0.1
#
	#var material := StandardMaterial3D.new()
	#material.albedo_color = Color("#80008080")  # 50% transparent purple
	#material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#material.flags_transparent = true
#
	#var multimesh := MultiMesh.new()
	#multimesh.mesh = sphere
	#multimesh.transform_format = MultiMesh.TRANSFORM_3D
	#multimesh.instance_count = instance_count
	#self.multimesh = multimesh
	#material_override = material
	#
#func addTrailNode(pos):
	#trail_nodes.append(pos)
	#var transform = Transform3D(Basis(), to_local(pos))
	#multimesh.set_instance_transform(trail_nodes.size() - 1, transform)
#
#func removeTrailNode(pos): 
	#for i in range(trail_nodes.size()): 
		#if trail_nodes[i] == pos: 
			#trail_nodes.pop_at(i)
			#var transform = Transform3D(Basis(), Vector3(0, -10, 0))
			#multimesh.set_instance_transform(i, transform)
			#return
