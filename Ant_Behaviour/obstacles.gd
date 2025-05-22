extends Node3D


func register_obstaces(): 
	for tree in get_children(): 
		tree.register() 
