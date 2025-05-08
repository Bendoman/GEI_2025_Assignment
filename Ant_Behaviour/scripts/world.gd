extends Node3D

var xr_interface: XRInterface
var _controller : XRController3D

signal left_ax_button_pressed
signal left_by_button_pressed
signal right_ax_button_pressed
signal right_by_button_pressed

signal left_trigger_click_pressed
signal right_trigger_click_pressed

@onready var xr_origin_3d : XROrigin3D = $XROrigin3D
@onready var xr_left_controller : XRController3D = xr_origin_3d.get_node("LeftHand")
@onready var xr_right_controller : XRController3D = xr_origin_3d.get_node("RightHand")

@onready var MASTER_BUS_ID = AudioServer.get_bus_index("Master")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	xr_interface = XRServer.find_interface('OpenXR')
	if(xr_interface and xr_interface.is_initialized()):
		print('OpenXR initialized')
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		
		xr_left_controller.button_pressed.connect(_on_left_button_pressed)
		xr_right_controller.button_pressed.connect(_on_right_button_pressed)
	else:
		print('Failed to initialize OpenXR')
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
