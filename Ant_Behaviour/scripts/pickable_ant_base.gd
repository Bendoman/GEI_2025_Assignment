extends Node3D

@onready var ant_base = $AntBase
func get_ready(pos): 
	var spawnPos = to_local(pos)
	position = Vector3(spawnPos.x, 0, spawnPos.z)
	ant_base = get_node("AntBase")

func init(): 
	ant_base.init()

func reset(): 
	ant_base.reset() 
