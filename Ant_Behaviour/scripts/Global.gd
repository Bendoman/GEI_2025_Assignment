extends Node

var ant_speed = .25
var warrior_speed = .5

var max_ants = 1000
var starting_ants = 1000

var display_dead_ants = false 
var display_trail_indicators = false 

var max_bases = 4

var stopped = true

signal toggling_stopped
func toggle_stopped(): 
	stopped = !stopped
	emit_signal("toggling_stopped")

signal max_ants_changed
func change_max_ants(value):
	if(stopped):
		max_ants = value 
		emit_signal("max_ants_changed")

signal starting_ants_changed
func change_starting_ants(value):
	if(stopped):
		starting_ants = value 
		emit_signal("starting_ants_changed")

signal add_base_signal
func add_base(): 
	if(stopped):
		print("Adding base in here")
		emit_signal("add_base_signal")

signal clear_bases_signal
func clear_bases(): 
	if(stopped):
		emit_signal("clear_bases_signal")

signal add_food_signal 
func add_food(): 
	if(stopped):
		print("adding food global")
		emit_signal("add_food_signal")

signal clear_food_signal
func clear_food(): 
	if(stopped):
		emit_signal("clear_food_signal")
