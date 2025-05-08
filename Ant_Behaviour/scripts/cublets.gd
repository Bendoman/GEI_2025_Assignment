extends Node3D
@export var material:StandardMaterial3D = null
@export var material2:StandardMaterial3D = null
@export var material3:StandardMaterial3D = null
var materials = [material, material2, material3]

# Called when the node enters the scene tree for the first time.
func _ready():
	for node in get_children():
		for cublet in node.get_children():
			if('Top' in node.name):
				cublet.get_child(1).set_surface_override_material(0, material)
			elif('Middle' in node.name):
				cublet.get_child(1).set_surface_override_material(0, material2)
			elif('Bottom' in node.name):
				cublet.get_child(1).set_surface_override_material(0, material3)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
