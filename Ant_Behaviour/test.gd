# World.gd
extends Node
class_name World


@onready var world_grid = $WorldGrid

@onready var ant_base = $AntBase
@onready var ant_base_2 = $AntBase2
var bases = []

@export var show_fps: bool = true
var _fps_label: Label

var stopped = false 

func _ready() -> void:
	#print(ant_base.antCount)
	bases = [ant_base, ant_base_2]
	if show_fps:
		var fps_layer := CanvasLayer.new()
		add_child(fps_layer)

		_fps_label = Label.new()
		_fps_label.text = "FPS: 0"
		# Position the label 10px in from the top-left
		_fps_label.position = Vector2(10, 10)
		fps_layer.add_child(_fps_label)

func add_food_source(): 
	pass

func remove_food_sources(): 
	pass

func add_base(): 
	pass

func remove_bases(): 
	pass

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
		
	for base in bases: 
		print("initializing team: ", base.team)

func _input(event):
	if Input.is_key_pressed(KEY_K):
		stopped = !stopped
		if(!stopped):
			Global.stopped = false
			init()
		else:
			Global.stopped = true 
			reset()
			
func _process(delta: float) -> void:
	if show_fps and _fps_label:
		_fps_label.text = "FPS: %d\nAnts: %d" % [Engine.get_frames_per_second(), ant_base.antCount]
