extends Node3D

@export var face_material:StandardMaterial3D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if("body" in child.name):
			child.set_surface_override_material(0, face_material)
			
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
