extends HSlider

func handle_max_ants_change():
	if(value > Global.max_ants):
		Global.change_starting_ants(Global.max_ants)	
		value = Global.max_ants

	max_value = Global.max_ants
	
	

func _ready(): 
	await get_tree().process_frame
	Global.connect("max_ants_changed", self.handle_max_ants_change)
	value = Global.starting_ants
	max_value = Global.max_ants
