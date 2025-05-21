extends HSlider

func _ready(): 
	await get_tree().process_frame
	value = Global.max_ants
