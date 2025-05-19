extends Node3D
@export var spawn_interval: float = 1       # seconds between spawns
@export var consume_interval: float = 1       # seconds between food consumption by existing ants

@export var spawn_position: Vector3 = Vector3.ZERO
@export var ant_scene: PackedScene

@export var team: int
@onready var ant_renderer = $AntRenderer
@onready var warrior_ant_renderer = $WarriorAntRenderer

@onready var base_mesh = $BaseMesh
var worker_progress
#@onready var worker_progress = $MeshInstance3D/WorkerProgress

var antCount: int

@export var ant_speed: int = 0.1
var world_grid

@onready var workers_label = $WorkerCountLabel/workersLabel
@onready var warriors_label = $WarriorCountLabel/warriorsLabel

var foodLevel: int
@onready var food_level_label = $FoodLevelLabel
@onready var worker_progress_bar = $MeshInstance3D/WorkerProgressBar


var nextAnt = "worker"
	
var progress := 0.0
var spawn_in_progress := false
var progress_duration := 3.0
var progress_elapsed := 0.0

var warriorCount: int

const ANT_BASE = preload("res://scenes/ant_base.gdshader")

func _ready():
	#await get_tree().process_frame
	world_grid = get_node("../WorldGrid") 
	# Spawn timer setup
	#var spawn_timer := Timer.new()
	#spawn_timer.wait_time = spawn_interval
	#spawn_timer.one_shot = false
	#spawn_timer.autostart = true
	#add_child(spawn_timer)
	#spawn_timer.timeout.connect(Callable(self, "progressAntCreation"))
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
	
	
func getAnt(team: int, index: int, type): 
	if(type == "worker"):
		return get_parent().bases[team].ant_renderer.ant_data[index]
	elif(type == "warrior"):
		return get_parent().bases[team].warrior_ant_renderer.ant_data[index]

func increaseWarriorCount():
	warriorCount += 1
	warriors_label.text = str(warriorCount)	

func increaseAntCount(): 
	antCount += 1
	workers_label.text = str(antCount)
	#ant_renderer.max_warriors = int(1 + (ant_renderer.ant_data.size() / 10))
	ant_renderer.max_warriors = 10
	#print("New max warriors: ", ant_renderer.max_warriors)


func incrementFoodLevel(amount: int): 
	foodLevel += amount
	food_level_label.text = str(foodLevel)
	if(foodLevel >= 10 and !spawn_in_progress):
		start_ant_spawn_progress()


func start_ant_spawn_progress():
	spawn_in_progress = true
	progress = 0.0
	progress_elapsed = 0.0
	foodLevel -= 10  # Consume food for the spawn

func reset_spawn_progress():
	spawn_in_progress = false
	progress = 0.0
	progress_elapsed = 0.0
	food_level_label.text = str(foodLevel)

	var mat = worker_progress.get_active_material(0)
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("progress", 0.0)
	
	if(foodLevel >= 10):
		start_ant_spawn_progress()


func _process(delta): 
	if spawn_in_progress:
		progress_elapsed += delta
		progress = clamp(progress_elapsed / progress_duration, 0.0, 1.0)

		var mat = worker_progress.get_active_material(0)
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("progress", progress)

		if progress >= 1.0:
			_spawn_ant()
			reset_spawn_progress()

#func progressAntCreation(): 
	#if(nextAnt == "worker"):
		#var mat = worker_progress.get_active_material(0)
		#if mat and mat is ShaderMaterial:
			#var tween := create_tween()
			#tween.tween_property(mat, "shader_parameter/progress", clamp(progress, 0.0, 1.0), 0.5)
		#
		#if(progress >= 1.0):
			#_spawn_ant()
			#progress = 0.0 
			#var tween := create_tween()
			#tween.tween_property(mat, "shader_parameter/progress", clamp(progress, 0.0, 1.0), 0.5)
		#else:
			#progress += 0.1
	#elif(nextAnt == "warrior"):
		#pass

func _spawn_ant() -> void:
	ant_renderer.spawn_ant()
	pass
