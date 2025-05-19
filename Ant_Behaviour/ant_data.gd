class_name ant_data 
extends Object 

var cell: Vector2i
var movement_cell: Vector2i

var path := []
var path_index := -1
var position: Vector3
var velocity: Vector3 = Vector3.ZERO

var global_position: Vector3 
var previous_global: Vector3 # Necessary? 

var dead: bool = false 
var backtracking: bool = false
var carrying_food: bool = false 
var targeting_food: bool = false 
var reporting_enemy: bool = false

var trail_index: int = -1
var following_trail: bool = false 

var food_source: Variant = null 
var fleeing_from: Variant = null

var theta = 0 