extends Node3D

#@export var hitzone: Area3D
@export var hitsound: AudioStreamMP3
@onready var pad_sound = get_node("pad_sound")

# Called when the node enters the scene tree for the first time.
func _ready():
	pad_sound.stream = hitsound
