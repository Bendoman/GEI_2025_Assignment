extends MultiMeshInstance3D

var instance_count = 100
@onready var ant_renderer = $"../AntRenderer"
@export var mesh_to_use: Mesh
@export var material_to_use: Material

func reset(): 
	self.multimesh = null 

func init(): 
	instance_count = int(ant_renderer.instance_count/10)
	# Create black material
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1.0, 0.0, 0.0)  
	
	# Create and configure the MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	self.multimesh = multimesh
	material_override = red

func _ready():
	await get_tree().process_frame
	init()

func addDeadAnt(antIndex: int):
	var ant = ant_renderer.antData[antIndex]
	var transform = Transform3D(Basis(), to_local(ant.global_position))
	multimesh.set_instance_transform(int(antIndex % instance_count), transform)
