extends Camera3D

@export var translationSpeed = 10
@export var rotationSpeed = 250

var translationAxis:float
var rotationAxis:float
var verticalRotationAxis:float
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(Vector3(0, 0, translationSpeed * delta * translationAxis))
	get_parent().rotate_y(deg_to_rad(rotationSpeed) * delta * rotationAxis)
	get_parent().rotate_x(deg_to_rad(rotationSpeed) * delta * verticalRotationAxis)
	pass

func _input(event):
	translationAxis = Input.get_axis("forward", "back")
	rotationAxis = Input.get_axis("rotate_left", "rotate_right")
	verticalRotationAxis = Input.get_axis("rotate_up", "rotate_down")
