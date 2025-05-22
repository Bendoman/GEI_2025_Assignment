extends Node3D
@export var spawn_interval: float = 1       # seconds between spawns
@export var consume_interval: float = 1       # seconds between food consumption by existing ants
@onready var pickable_object = $"../PickableObject"

@export var spawn_position: Vector3 = Vector3.ZERO

@export var team: int
@onready var ant_renderer = $AntRenderer
@onready var warrior_ant_renderer = $WarriorAntRenderer

@onready var base_mesh = $BaseMesh
var worker_progress
#@onready var worker_progress = $MeshInstance3D/WorkerProgress

var antCount: int
@onready var max_warriors_number = $WarriorCountLabel/maxWarriorsLabel/MaxWarriorsNumber
@onready var carried_food_renderer = $CarriedFoodRenderer

var world_grid

@onready var workers_label = $WorkerCountLabel/workersLabel
@onready var warriors_label = $WarriorCountLabel/warriorsLabel

var foodLevel: int
@onready var food_level_label = $FoodLevelLabel
@onready var worker_progress_bar = $MeshInstance3D/WorkerProgressBar
@onready var next_ant_label = $FoodLevelLabel/NextAntLabel
@onready var dead_warrior_renderer = $DeadWarriorRenderer


var nextAnt = "worker"
	
var progress := 0.0
var spawn_in_progress := false
var progress_duration := 3.0
var progress_elapsed := 0.0

var warriorCount: int
var warriorQueue: int 


const ANT_BASE = preload("res://scenes/ant_base.gdshader")


func init(): 
	#Global.starting_ants = 1
	ant_renderer.init()
	warrior_ant_renderer.init()
	carried_food_renderer.init()
	dead_warrior_renderer.init()
	
	
func reset(): 
	# Reset own variables
	antCount = 0
	warriorCount = 0
	warriorQueue = 0 
	nextAnt = "worker"
	foodLevel = 0
	
	next_ant_label.text = "Worker spawning next"
	
	
	progress = 0.0 
	progress_elapsed = 0.0 
	spawn_in_progress = false 
	
	var mat = worker_progress.get_active_material(0)
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("progress", progress)
	
	workers_label.text = "0"
	warriors_label.text = "0"
	food_level_label.text = "0"
	max_warriors_number.text = "0"
	
	# Reset multimesh
	ant_renderer.reset()
	warrior_ant_renderer.reset()
	carried_food_renderer.reset()
	dead_warrior_renderer.reset()
	
var mat 
func _ready():
	world_grid = get_node("../../WorldGrid") 

	var mesh_instance := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.5, 1.5)  # Set size as needed
	mesh_instance.mesh = quad
	mesh_instance.rotation_degrees.x = -90
	
	var shader_material = ShaderMaterial.new() 
	shader_material.shader = ANT_BASE
	mesh_instance.material_override = shader_material
	
	worker_progress = mesh_instance
	add_child(worker_progress)
	mat = worker_progress.get_active_material(0)
	



func getAnt(team: int, index: int, type): 
	if(type == "worker"):
		return get_parent().get_parent().bases[team].ant_renderer.antData[index]
	elif(type == "warrior"):
		return get_parent().get_parent().bases[team].warrior_ant_renderer.antData[index]

func decreaseWarriorCount(): 
	if(foodLevel >= 20 and !spawn_in_progress and warriorQueue > 0): 
		mat.set_shader_parameter("color", Vector4(1.0, 0.0, 0.0, 1.0))
		start_ant_spawn_progress(10)
		
	ant_renderer.currentWarriors -= 1
	warriorCount -= 1
	warriors_label.text = str(warriorCount)	
	
func increaseWarriorCount():
	warriorCount += 1
	warriors_label.text = str(warriorCount)	

func decreaseAntCount(): 
	if(foodLevel >= 10 and !spawn_in_progress and warriorQueue <= 0): 
		mat.set_shader_parameter("color", Vector4(1.0, 0.0, 0.0, 1.0))
		start_ant_spawn_progress(10)
		
	antCount -= 1
	workers_label.text = str(antCount)
	ant_renderer.maxWarriors = int(1 + (ant_renderer.antData.size() / 50))
	max_warriors_number.text = str(ant_renderer.maxWarriors)
	


func increaseAntCount(): 
	antCount += 1
	workers_label.text = str(antCount)
	ant_renderer.maxWarriors = int(1 + (ant_renderer.antData.size() / 50))
	max_warriors_number.text = str(ant_renderer.maxWarriors)
	#print("New max warriors: ", ant_renderer.maxWarriors)

func addToWarriorQueue(): 
	warriorQueue += 1
	next_ant_label.text = "Warrior spawning next"

func incrementFoodLevel(amount: int): 
	foodLevel += amount
	food_level_label.text = str(foodLevel)
	
	if(!spawn_in_progress):
		if(warriorQueue > 0):
			next_ant_label.text = "Warrior spawning next"
			if(foodLevel >= 20):
				mat.set_shader_parameter("color", Vector4(1.0, 0.0, 0.0, 1.0))
				start_ant_spawn_progress(20)
		else:
			next_ant_label.text = "Worker spawning next"
			if(foodLevel >= 10):
				mat.set_shader_parameter("color", Vector4(0.0, 1.0, 0.0, 1.0))
				start_ant_spawn_progress(10)


func start_ant_spawn_progress(consumption):
	if(consumption == 10):
		# worker
		if(ant_renderer.antsAlive >= ant_renderer.instance_count):
			return
	else: 
		#warrior
		if(warrior_ant_renderer.antsAlive >= warrior_ant_renderer.instance_count):
			return
		
	spawn_in_progress = true
	progress = 0.0
	progress_elapsed = 0.0
	foodLevel -= consumption  # Consume food for the spawn

func reset_spawn_progress():
	spawn_in_progress = false
	progress = 0.0
	progress_elapsed = 0.0
	food_level_label.text = str(foodLevel)

	var mat = worker_progress.get_active_material(0)
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("progress", 0.0)
	
	if(warriorQueue > 0):
		next_ant_label.text = "Warrior spawning next"
		if(foodLevel >= 20):
			mat.set_shader_parameter("color", Vector4(1.0, 0.0, 0.0, 1.0))
			start_ant_spawn_progress(20)
	else:
		next_ant_label.text = "Worker spawning next"
		if(foodLevel >= 10):
			mat.set_shader_parameter("color", Vector4(0.0, 1.0, 0.0, 1.0))
			start_ant_spawn_progress(10)


func _process(delta): 
	if(Global.stopped): 
		position = Vector3(pickable_object.position.x, position.y, pickable_object.position.z)
	
	if spawn_in_progress:
		progress_elapsed += delta
		progress = clamp(progress_elapsed / progress_duration, 0.0, 1.0)

		#var mat = worker_progress.get_active_material(0)
		#if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("progress", progress)

		if progress >= 1.0:
			_spawn_ant()
			reset_spawn_progress()

func _spawn_ant() -> void:
	if(warriorQueue > 0):
		warrior_ant_renderer.spawn_ant()
		warriorQueue -= 1 
	else:
		ant_renderer.spawn_ant()
 
		
