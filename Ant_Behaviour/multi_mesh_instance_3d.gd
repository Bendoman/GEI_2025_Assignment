extends MultiMeshInstance3D

@export var instance_count := 2000
@export var spawn_radius := 20.0
@export var mesh_to_use: Mesh
@export var material_to_use: Material

var paths = [] 
var antData = [] 

func _ready():
	# Create and configure the MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	self.multimesh = multimesh

	# Set transform for each instance (e.g. random spread)
	for i in instance_count:
		var pos = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * randf() * spawn_radius
		var transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(i, transform)
		antData.append({
			"position": pos, 
			"path": []
		})


func _physics_process(delta):
	return
	for i in antData.size():
		var pos = antData[i].position + Vector3(-1, 0, 0)
		antData[i].position = pos
		var transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(i, transform)
