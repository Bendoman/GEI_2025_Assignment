extends Node3D

@onready var interactable_slider = $SliderOrigin/InteractableSlider
@onready var sfxr_stream_player_3d = $SfxrStreamPlayer3D
@export var hitzone: Area3D
@export var theremin_stream: AudioStreamWAV
@onready var frame = get_node("Frame")
@onready var handle_mesh = $SliderOrigin/InteractableSlider/SliderBody/handleMesh

const THEREMIN_HANDLE = preload("res://materials/theremin_handle.tres")
const THEREMIN_HANDLE_ACTIVE = preload("res://materials/theremin_handle_active.tres")

signal deactivateSignal

# Called when the node enters the scene tree for the first time.
func _ready():
	sfxr_stream_player_3d.stream = theremin_stream
	interactable_slider.connect("slider_moved", self.sliderMoved)
	connect("deactivateSignal", self.onDeactivate)

func onDeactivate():
	sfxr_stream_player_3d.stop()	

func sliderMoved(position):		
	#print('slider moved: ', sfxr_stream_player_3d)
	if(position == 0):
		handle_mesh.set_surface_override_material(0, THEREMIN_HANDLE)
		sfxr_stream_player_3d.stop()
	elif(not sfxr_stream_player_3d.playing):
		handle_mesh.set_surface_override_material(0, THEREMIN_HANDLE_ACTIVE)
		sfxr_stream_player_3d.play()
	 
	var output = remap(position, 0, 0.45, 600, 2200)
	sfxr_stream_player_3d.stream.mix_rate = output
	#print(output)

func onPointer(event):
	print('pointer event: ', event)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
