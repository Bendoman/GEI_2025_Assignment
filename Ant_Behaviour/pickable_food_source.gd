extends Node3D
@onready var food_source = $FoodSource
@onready var pickable_object = $PickableObject

func init(): 
	food_source = get_node("FoodSource")
	pickable_object = get_node("PickableObject")
	
	food_source.init()
