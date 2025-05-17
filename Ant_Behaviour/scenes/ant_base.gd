extends Node3D
@export var spawn_interval: float = 0.25       # seconds between spawns
@export var spawn_position: Vector3 = Vector3.ZERO
@export var ant_scene: PackedScene

@export var team: int
@onready var ant_renderer = $AntRenderer

var antCount: int
var world_grid

func _ready():
	world_grid = get_node("../WorldGrid") 
	world_grid.test()
	# Spawn timer setup
	var spawn_timer := Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	#add_child(spawn_timer)
	#spawn_timer.timeout.connect(Callable(self, "_spawn_ant"))

func _spawn_ant() -> void:
	if not ant_scene:
		push_warning("No Ant scene assigned for spawning!")
		return
	#if antCount > 15:
		#return 
		
	var ant = ant_scene.instantiate()
	add_child(ant)
	antCount += 1
	# Position new ant at spawn point
	ant.global_transform.origin = spawn_position
