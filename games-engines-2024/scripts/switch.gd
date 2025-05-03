extends Node3D

@export var defaultMaterial: StandardMaterial3D
@export var activeMaterial: StandardMaterial3D
@export var hitzone: Area3D

signal activateSignal
signal deactivateSignal

@onready var button_body:StaticBody3D = get_node('button')
@onready var button_mesh:MeshInstance3D = button_body.get_node('button')
@onready var effects_bus_index = AudioServer.get_bus_index("effects_bus")
@onready var theremin_effects_bus_index = AudioServer.get_bus_index("theremin_effects")

const SWITCH_PRESSED = preload("res://materials/switch_pressed.tres")
const SWITCH_UNPRESSED = preload("res://materials/switch_unpressed.tres")

@export var active:bool = false
@export var effect:AudioEffect

var effectIndex = null
func onHit():
	active = !active
	if(active): 
		button_mesh.set_surface_override_material(0, SWITCH_PRESSED)
		AudioServer.add_bus_effect(effects_bus_index, effect, 0)
		if('Reverb' not in effect.get_class()):
			AudioServer.add_bus_effect(theremin_effects_bus_index, effect, 0)
		#print('Adding effect: ', effect)
	else: 
		button_mesh.set_surface_override_material(0, SWITCH_UNPRESSED)
		var effect_count = AudioServer.get_bus_effect_count(effects_bus_index)
		for i in range(effect_count):
			var e = AudioServer.get_bus_effect(effects_bus_index, i)
			if(e and e.get_class() == effect.get_class()):
				#print('removing effect: ', AudioServer.get_bus_effect(effects_bus_index, i))
				AudioServer.remove_bus_effect(effects_bus_index, i)
				if('Reverb' not in e.get_class()):
					AudioServer.remove_bus_effect(theremin_effects_bus_index, i)

func onDrop():
	print('deactivated')

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node('InteractableAreaButton').connect("hitSignal", self.onHit)
