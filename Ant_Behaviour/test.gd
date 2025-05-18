# World.gd
extends Node
class_name World


@onready var world_grid = $WorldGrid

@onready var ant_base = $AntBase
@onready var ant_base_2 = $AntBase2
var bases

@export var show_fps: bool = true
var _fps_label: Label

func _ready() -> void:
	bases = [ant_base, ant_base_2]
	#print(ant_base.antCount)
	if show_fps:
		var fps_layer := CanvasLayer.new()
		add_child(fps_layer)

		_fps_label = Label.new()
		_fps_label.text = "FPS: 0"
		# Position the label 10px in from the top-left
		_fps_label.position = Vector2(10, 10)
		fps_layer.add_child(_fps_label)

func _input(event):
	if Input.is_key_pressed(KEY_K):
		world_grid.printGrid()

func _process(delta: float) -> void:
	if show_fps and _fps_label:
		_fps_label.text = "FPS: %d\nAnts: %d" % [Engine.get_frames_per_second(), ant_base.antCount]
