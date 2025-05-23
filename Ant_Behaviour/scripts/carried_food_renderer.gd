extends MultiMeshInstance3D

var team 
var foodData = []
var instance_count

@onready var ant_renderer = $"../AntRenderer"
@onready var workers_label = $"../WorkerCountLabel/workersLabel"
@onready var warriors_label = $"../WarriorCountLabel/warriorsLabel"

func _ready():
	await get_tree().process_frame
	team = get_parent().team
	instance_count = ant_renderer.instance_count
	
	var sphere := SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#FFE60080")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	
	var multimesh := MultiMesh.new()
	multimesh.mesh = sphere
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	self.multimesh = multimesh
	material_override = material
	
	for i in instance_count:
		var transform = Transform3D(Basis(), Vector3(0, -10, 0))
		multimesh.set_instance_transform(i, transform)
		foodData.append({"ant": null})

func reset(): 
	foodData = [] 
	self.multimesh = null

func init(): 
	instance_count = Global.max_ants
	
	var sphere := SphereMesh.new()
	sphere.radius = 0.02
	sphere.height = 0.04
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#FFE60080")  # 50% transparent yellow
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	
	var multimesh := MultiMesh.new()
	multimesh.mesh = sphere
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	self.multimesh = multimesh
	material_override = material
	
	for i in instance_count:
		var transform = Transform3D(Basis(), Vector3(0, -10, 0))
		multimesh.set_instance_transform(i, transform)
		foodData.append({"ant": null})
var instances = 0

func addCarriedFood(antIndex: int):
	foodData[antIndex].ant = ant_renderer.antData[antIndex]

func removeCarriedFood(antIndex: int):
	foodData[antIndex].ant = null
	var transform = Transform3D(Basis(), Vector3(0, -10, 0))
	multimesh.set_instance_transform(antIndex, transform)

func _physics_process(delta):
	for i in foodData.size():
		var ant = foodData[i].ant
		if(ant == null):
			continue
		var transform = Transform3D(Basis(), ant.position + Vector3(0, 0.025, 0))
		multimesh.set_instance_transform(i, transform)
