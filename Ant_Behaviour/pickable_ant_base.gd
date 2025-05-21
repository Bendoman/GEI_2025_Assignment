extends Node3D

@onready var ant_base = $AntBase
func get_ready(): 
	ant_base = get_node("AntBase")

func init(): 
	ant_base.init()

func reset(): 
	ant_base.reset() 
