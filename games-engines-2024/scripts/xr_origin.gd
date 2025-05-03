extends XROrigin3D

@onready var control_pad = $ControlPad

func grip_held(): 
	#print('grip held in here')
	control_pad.get_node("Viewport2Din3D").visible = !control_pad.get_node("Viewport2Din3D").visible
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().connect("left_trigger_click_pressed", self.grip_held)
	get_parent().connect("right_trigger_click_pressed", self.grip_held)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
