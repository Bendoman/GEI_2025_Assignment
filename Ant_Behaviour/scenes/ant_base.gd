extends Node3D
@export var spawn_interval: float = 1       # seconds between spawns
@export var consume_interval: float = 1       # seconds between food consumption by existing ants

@export var spawn_position: Vector3 = Vector3.ZERO
@export var ant_scene: PackedScene

@export var team: int
@onready var ant_renderer = $AntRenderer
@onready var worker_progress = $MeshInstance3D/WorkerProgress

var antCount: int
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

func increaseWarriorCount():
	warriorCount += 1
	warriors_label.text = str(warriorCount)	

func increaseAntCount(): 
	antCount += 1
	workers_label.text = str(antCount)

func incrementFoodLevel(amount: int): 
	foodLevel += amount
	food_level_label.text = str(foodLevel)
	if(foodLevel >= 10 and !spawn_in_progress):
		start_ant_spawn_progress()
func _ready():
	world_grid = get_node("../WorldGrid") 
	# Spawn timer setup
	var spawn_timer := Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	#add_child(spawn_timer)
	#spawn_timer.timeout.connect(Callable(self, "progressAntCreation"))

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
