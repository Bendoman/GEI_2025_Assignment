extends Node3D

@onready var abdomen = $Abdomen
@onready var head = $Head
@onready var front_legs = $Front_Legs
@onready var middle_legs = $Middle_Legs
@onready var back_legs = $Back_Legs

func _ready(): 
	var mesh = ArrayMesh.new()
	
