extends Node3D


func _ready(): 
	for tree in get_children(): 
		tree.register() 
