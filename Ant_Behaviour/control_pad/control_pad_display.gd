extends TabContainer


## Signal emitted when the control pad hand is switched
signal switch_hand(hand)

## Signal emitted when requested to go to the main scene
signal main_scene

## Signal emitted when requested to quit
signal quit


var _tween : Tween

var _player_body : XRToolsPlayerBody
@onready var max_ants_label = $Settings/VBoxContainer/MaxAnts/MaxAntsLabel
@onready var starting_ants_label = $Settings/VBoxContainer/StartingAnts/StartingAntsLabel

@onready var max_ants_slider = $Settings/VBoxContainer/MaxAnts/MaxAntsSlider
@onready var starting_ants_slider = $Settings/VBoxContainer/StartingAnts/StartingAntsSlider

@onready var add_base_button = $Settings/VBoxContainer/BaseContainer/AddBaseButton
@onready var clear_bases_button = $Settings/VBoxContainer/BaseContainer/ClearBasesButton

@onready var add_food_button = $Settings/VBoxContainer/FoodContainer/AddFoodButton
@onready var clear_food_button = $Settings/VBoxContainer/FoodContainer/ClearFoodButton

@onready var start_button = $Settings/VBoxContainer/StartStop/StartButton
@onready var stop_button = $Settings/VBoxContainer/StartStop/StopButton

var controls = [] 

func handle_stopped_toggle(): 
	print(Global.stopped)
	if(Global.stopped):
		print("Enabling buttons")

		max_ants_slider.editable = true
		starting_ants_slider.editable = true
		add_base_button.disabled = false
		clear_bases_button.disabled = false
		add_food_button.disabled = false
		clear_food_button.disabled = false
	else: 

		max_ants_slider.editable = false
		starting_ants_slider.editable = false
		
		add_base_button.disabled = true
		clear_bases_button.disabled = true
		add_food_button.disabled = true
		clear_food_button.disabled = true

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Apply initial scale
	#$Settings/VBoxContainer/Scale/BodyScaleSlider.value = XRServer.world_scale

	# Find the player body
	_player_body = XRToolsPlayerBody.find_instance(self)
	Global.connect("toggling_stopped", self.handle_stopped_toggle)



# Called to refresh the display
func _on_refresh_timer_timeout():
	if _player_body and $Settings.visible:
		var pos := _player_body.global_position
		var vel := _player_body.velocity
		var pos_str := "%8.3f, %8.3f, %8.3f" % [pos.x, pos.y, pos.z]
		var vel_str := "%8.3f, %8.3f, %8.3f" % [vel.x, vel.y, vel.z]
		#$Body/VBoxContainer/Position/Value.text = pos_str
		#$Body/VBoxContainer/Velocity/Value.text = vel_str

# Handle user changing the body scale slider
func _on_body_scale_slider_value_changed(value : float) -> void:
	Global.change_max_ants(value)
	max_ants_label.text = "Max ants: " + str(value)
	print(value)

func _on_starting_ants_slider_value_changed(value):
	Global.change_starting_ants(value)
	starting_ants_label.text = "Starting ants: " + str(value)
	print(value)

# Handle user selecting main scene
func _on_main_scene_pressed():
	main_scene.emit()

func _on_quit_pressed():
	quit.emit()

# Called by the tweening to change the world scale
func _set_world_scale(new_scale : float) -> void:
	XRServer.world_scale = new_scale


func _on_start_button_up():
	print("Starting")
	if(Global.stopped): 
		Global.toggle_stopped()

func _on_stop_button_up():
	print("Stopping")
	if(!Global.stopped): 
		Global.toggle_stopped()
		
func _on_add_food_button_button_up():
	Global.add_food()

func _on_clear_food_button_button_up():
	Global.clear_food()

func _on_add_base_button_button_up():
	print("Adding base")
	Global.add_base()

func _on_clear_bases_button_button_up():
	Global.clear_bases()
