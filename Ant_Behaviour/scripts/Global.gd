extends Node

var ant_speed = .25
var warrior_speed = .5

var max_ants = 500
var starting_ants = 500

var display_dead_ants = false 
var display_trail_indicators = false 

var max_bases = 4

var stopped = false 

signal test
func test_emit():
	print("emitting")
	emit_signal("test")
