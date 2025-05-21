# World.gd
extends Node
class_name World
var xr_interface: XRInterface
var _controller : XRController3D

signal left_ax_button_pressed
signal left_by_button_pressed
signal right_ax_button_pressed
signal right_by_button_pressed

signal left_trigger_click_pressed
signal right_trigger_click_pressed

@onready var xr_origin_3d : XROrigin3D = $XROrigin3D
#@onready var xr_left_controller : XRController3D = xr_origin_3d.get_node("LeftHand")
#@onready var xr_right_controller : XRController3D = xr_origin_3d.get_node("RightHand")


@export var ant_base_scene: PackedScene
@export var food_source_scene: PackedScene

@onready var world_grid = $WorldGrid

@onready var ant_base = $AntBase
@onready var ant_base_2 = $AntBase2
var bases = []

@export var show_fps: bool = true
var _fps_label: Label

var stopped = false 
var basesNumber = 0 
var foodSources = 0 

func test_signal(): 
	print("in here on signal")
	
func _ready() -> void:
	#xr_interface = XRServer.find_interface('OpenXR')
	#if(xr_interface and xr_interface.is_initialized()):
		#print('OpenXR initialized')
		#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		#get_viewport().use_xr = true
		#
		#xr_left_controller.button_pressed.connect(_on_left_button_pressed)
		#xr_right_controller.button_pressed.connect(_on_right_button_pressed)
	#else:
		#print('Failed to initialize OpenXR')
		
	#print(ant_base.antCount)
	Global.connect("add_base_signal", self.add_base)
	Global.connect("clear_bases_signal", self.remove_bases)
	
	Global.connect("add_food_signal", self.add_food_source)
	Global.connect("clear_food_signal", self.remove_food_sources)

	Global.connect("toggling_stopped", self.toggle_stop)

	#bases = [ant_base, ant_base_2]
	for child in get_children(): 
		if("AntBase" in child.name):
			basesNumber += 1
			child.ant_base.team = bases.size()
			bases.append(child.ant_base)
	
	if show_fps:
		var fps_layer := CanvasLayer.new()
		add_child(fps_layer)

		_fps_label = Label.new()
		_fps_label.text = "FPS: 0"
		# Position the label 10px in from the top-left
		_fps_label.position = Vector2(10, 10)
		fps_layer.add_child(_fps_label)

func toggle_stop(): 
	if(!Global.stopped):
		init()
	else:
		reset()
	pass

func add_food_source(): 
	foodSources += 1
	var instance = food_source_scene.instantiate()
	instance.name = instance.name + str(foodSources)
	add_child(instance)
	
func remove_food_sources():
	foodSources = 0 
	for child in get_children(): 
		if("FoodSource" in child.name):
			child.queue_free()

func add_base(): 
	print("reseiving signal")
	basesNumber += 1
	if(bases.size() >= Global.max_bases):
		return 
		
	print("add base")
	var instance = ant_base_scene.instantiate()
	#instance.position = Vector3(0, 0.175, 0)
	instance.get_ready()
	instance.ant_base.team = bases.size()
	instance.name = instance.name + str(basesNumber)
	
	bases.append(instance.ant_base)
	add_child(instance)
	pass

func remove_bases(): 
	basesNumber = 0 
	Global.stopped = true
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
		Global.toggle_stopped()


func _process(delta: float) -> void:
	pass
	#if show_fps and _fps_label:
		#_fps_label.text = "FPS: %d\nAnts: %d" % [Engine.get_frames_per_second(), ant_base.antCount]


func _on_left_button_pressed(button_name: String) -> void:
	match button_name:
		"ax_button":
			emit_signal("left_ax_button_pressed")
		"by_button":
			emit_signal("left_by_button_pressed")
		"trigger_click":
			emit_signal("left_trigger_click_pressed")
func _on_right_button_pressed(button_name: String) -> void:
	match button_name:
		"ax_button":
			emit_signal("right_ax_button_pressed")
		"by_button":
			emit_signal("right_by_button_pressed")
		"trigger_click":
			emit_signal("right_trigger_click_pressed")
