extends Node3D
@onready var food_source = $FoodSource
@onready var pickable_object = $PickableObject

func get_ready(pos):
	var spawnPos = to_local(pos)
	position = Vector3(spawnPos.x, 0, spawnPos.z)

func init(): 
	food_source = get_node("FoodSource")
	pickable_object = get_node("PickableObject")
	
	food_source.init()
