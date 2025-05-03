extends Node3D

signal left_ax_button_pressed
signal left_by_button_pressed
signal right_ax_button_pressed
signal right_by_button_pressed

@onready var click_sound = $clickSound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent = get_parent()
	if(parent): 
		parent.connect('left_ax_button_pressed', self.on_left_ax_click)
		parent.connect('left_by_button_pressed', self.on_left_by_click)
		parent.connect('right_ax_button_pressed', self.on_right_ax_click)
		parent.connect('right_by_button_pressed', self.on_right_by_click)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_left_ax_click(): 
	emit_signal("left_ax_button_pressed")
func on_left_by_click(): 
	emit_signal("left_by_button_pressed")
func on_right_ax_click(): 
	emit_signal("right_ax_button_pressed")
func on_right_by_click(): 
	emit_signal("right_by_button_pressed")
