# World.gd
extends Node
class_name World


@export var ant_base_scene: PackedScene
@export var food_source_scene: PackedScene

@onready var world_grid = $WorldGrid

@onready var ant_base = $AntBase
@onready var ant_base_2 = $AntBase2
var bases = []

@export var show_fps: bool = true
var _fps_label: Label

var stopped = false 

func test_signal(): 
	print("in here on signal")
	
func _ready() -> void:
	#print(ant_base.antCount)
	Global.connect("test", self.test_signal)

	#bases = [ant_base, ant_base_2]
	for child in get_children(): 
		if("AntBase" in child.name):
			bases.append(child)
	
	if show_fps:
		var fps_layer := CanvasLayer.new()
		add_child(fps_layer)

		_fps_label = Label.new()
		_fps_label.text = "FPS: 0"
		# Position the label 10px in from the top-left
		_fps_label.position = Vector2(10, 10)
		fps_layer.add_child(_fps_label)

var foodSources = 0 
func add_food_source(): 
	foodSources += 1
	var instance = food_source_scene.instantiate()
	instance.name = instance.name + str(foodSources)
	add_child(instance)
	print(get_children())
	
func remove_food_sources():
	foodSources = 0 
	for child in get_children(): 
		if("FoodSource" in child.name):
			child.queue_free()

var basesNumber = 0 
func add_base(): 
	basesNumber += 1
	if(bases.size() >= Global.max_bases):
		return 
		
	print("add base")
	var instance = ant_base_scene.instantiate()
	instance.position = Vector3(0, 0.175, 0)
	instance.team = bases.size()
	instance.name = instance.name + str(basesNumber)
	
	add_child(instance)
	bases.append(instance)
	pass

func remove_bases(): 
	basesNumber = 0 
	print("remove bases")
	for child in get_children(): 
		if("AntBase" in child.name):
			child.queue_free()
	bases = [] 

func reset(): 
	world_grid.reset_grid()
	
	for child in get_children(): 
		if("AntBase" in child.name):
			child.reset() 
		elif("FoodSource" in child.name): 
			child.init() 
		
func init(): 
	world_grid.reset_grid()
	
	for child in get_children(): 
		if("AntBase" in child.name):
			child.init()
		elif("FoodSource" in child.name): 
			child.init() 
			
			#child.team = bases.size() 
			#bases.append(child)
			#if(Global.stopped):
				#child.reset() 
			#else:
				#child.init() 
		
	#for base in bases: 
		#print("initializing team: ", base.team)

func _input(event):
	if Input.is_key_pressed(KEY_F):
		remove_food_sources()
	
	if Input.is_key_pressed(KEY_D):
		add_food_source()
	
	if Input.is_key_pressed(KEY_S):
		remove_bases()
	
	if Input.is_key_pressed(KEY_A):
		add_base()
	
	if Input.is_key_pressed(KEY_K):
		Global.test_emit()
		stopped = !stopped
		if(!stopped):
			Global.stopped = false
			init()
		else:
			Global.stopped = true 
			reset()
			
func _process(delta: float) -> void:
	pass
	#if show_fps and _fps_label:
		#_fps_label.text = "FPS: %d\nAnts: %d" % [Engine.get_frames_per_second(), ant_base.antCount]
