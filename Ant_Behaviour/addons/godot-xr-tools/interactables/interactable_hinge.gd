@tool
class_name XRToolsInteractableHinge
extends XRToolsInteractableHandleDriven

signal onSelectSignal
signal onDeselectSignal
signal selectableSignal
signal unselectableSignal
signal playSnapSound

var selectable: bool = true
var selected: bool = false

var audioStream: AudioStreamPlayer3D = null

const handleMaterial = preload("res://materials/handle.tres")
const transparentMaterial = preload("res://materials/transparent.tres")
## XR Tools Interactable Hinge script
##
## The interactable hinge is a hinge transform node controlled by the
## player through one or more [XRToolsInteractableHandle] instances.
##
## The hinge rotates itelf around its local X axis, and so should be
## placed as a child of a node to translate and rotate as appropriate.
##
## The interactable hinge is not a [RigidBody3D], and as such will not react
## to any collisions.


## Signal for hinge moved
signal hinge_moved(angle)
var angular_velocity : Vector3 = Vector3()

## Hinge minimum limit
@export var hinge_limit_min : float = -45.0: set = _set_hinge_limit_min

## Hinge maximum limit
@export var hinge_limit_max : float = 45.0: set = _set_hinge_limit_max

## Hinge step size (zero for no steps)
@export var hinge_steps : float = 0.0: set = _set_hinge_steps

## Hinge position
@export var hinge_position : float = 0.0: set = _set_hinge_position

## Default position
@export var default_position : float = 0.0: set = _set_default_position

## If true, the hinge moves to the default position when releases
@export var default_on_release : bool = false

var previousBasis

# Hinge values in radians
@onready var _hinge_limit_min_rad : float = deg_to_rad(hinge_limit_min)
@onready var _hinge_limit_max_rad : float = deg_to_rad(hinge_limit_max)
@onready var _hinge_steps_rad : float = deg_to_rad(hinge_steps)
@onready var _hinge_position_rad : float = deg_to_rad(hinge_position)
@onready var _default_position_rad : float = deg_to_rad(default_position)

# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableHinge" or super(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	for node in get_node('rotation_plane_body').get_children():
		#print(node)
		if('handle' not in node.name):
			continue
		node.set_surface_override_material(0, handleMaterial)
	super()

	# Set the initial position to match the initial hinge position value
	transform = Transform3D(
		Basis.from_euler(Vector3(_hinge_position_rad, 0, 0)),
		Vector3.ZERO
	)
	previousBasis = transform.basis
	
	# Connect signals
	if released.connect(_on_hinge_released):
		push_error("Cannot connect hinge released signal")
	connect('selectableSignal', self.setSelectable)
	connect('unselectableSignal', self.setUnselectable)


func setSelectable():
	#print('selectable')
	for node in get_node('rotation_plane_body').get_children():
		#print(node)
		if('handle' not in node.name):
			continue
		node.set_surface_override_material(0, handleMaterial)
#	TODO: Find root cause of this bug instead of this workaround if there's time
	await get_tree().create_timer(0.05).timeout
	selectable = true


func setUnselectable():
	selectable = false
	if(selected):
		return
		
	for node in get_node('rotation_plane_body').get_children():
		if('handle' not in node.name):
			continue
		node.set_surface_override_material(0, transparentMaterial)
		#print('setting transparent')


var previousOffset = 0
# Called every frame when one or more handles are held by the player
func _process(_delta: float) -> void:
	if not selectable and not selected:
		return
		
	if not selected:
		var emit_nodes = [
			get_node("rotation_plane_body/body_mesh/RotationArea"), 
			get_node("rotation_plane_body"), 
			get_node("rotation_plane_body/body_mesh"),
			get_parent().get_parent()
		]
		selected = true
		emit_signal('onSelectSignal', emit_nodes)
	
	# Get the total handle angular offsets
	var offset_sum := 0.0
	for item in grabbed_handles:
		var handle := item as XRToolsInteractableHandle
		var to_handle: Vector3 = handle.global_transform.origin * global_transform
		var to_handle_origin: Vector3 = handle.handle_origin.global_transform.origin * global_transform
		to_handle.x = 0.0
		to_handle_origin.x = 0.0
		offset_sum += to_handle_origin.signed_angle_to(to_handle, Vector3.RIGHT)

	# Average the angular offsets
	var offset := offset_sum / grabbed_handles.size()
	
	# Move the hinge by the requested offset
	move_hinge(_hinge_position_rad + offset)

	previousOffset = offset

func move_hinge(position: float) -> void:
	# Do the hinge move
	position = _do_move_hinge(position)
	if position == _hinge_position_rad:
		return
		
	# Update the current positon
	_hinge_position_rad = position
	hinge_position = rad_to_deg(position)
	
	# Emit the moved signal
	emit_signal("hinge_moved", hinge_position)

# Handle release of hinge
func _on_hinge_released(_interactable: XRToolsInteractableHinge):
	if default_on_release:
		move_hinge(_default_position_rad)

# Called when hinge_limit_min is set externally
func _set_hinge_limit_min(value: float) -> void:
	hinge_limit_min = value
	_hinge_limit_min_rad = deg_to_rad(value)


# Called when hinge_limit_max is set externally
func _set_hinge_limit_max(value: float) -> void:
	hinge_limit_max = value
	_hinge_limit_max_rad = deg_to_rad(value)


# Called when hinge_steps is set externally
func _set_hinge_steps(value: float) -> void:
	hinge_steps = value
	_hinge_steps_rad = deg_to_rad(value)


# Called when hinge_position is set externally
func _set_hinge_position(value: float) -> void:
	var position := deg_to_rad(value)
	position = _do_move_hinge(position)
	hinge_position = rad_to_deg(position)
	_hinge_position_rad = position


# Called when default_position is set externally
func _set_default_position(value: float) -> void:
	default_position = value
	_default_position_rad = deg_to_rad(value)


# Do the hinge move
func _do_move_hinge(position: float) -> float:
	# Apply hinge step-quantization
	if _hinge_steps_rad:
		position = round(position / _hinge_steps_rad) * _hinge_steps_rad
	# Move if necessary
	if position != _hinge_position_rad:
		transform.basis = Basis.from_euler(Vector3(position, 0.0, 0.0))
	# Return the updated position
	return position


var snapAngles = [0, 90, 180, 270, 360]
var audioSnapAngles = [0, 90, -90, 180, -180]
func _physics_process(delta: float) -> void:
	if(grabbed_handles.size() == 0):
		move_hinge(_hinge_position_rad + previousOffset)
		if(previousOffset < 0):
			previousOffset += abs(previousOffset) / 100
		elif(previousOffset > 0):
			previousOffset -= abs(previousOffset) / 100			
		
		if(previousOffset != 0 and abs(0 - previousOffset) <= 0.008):
			previousOffset = 0
			var hingePos = hinge_position
			while(hingePos < 0):
				hingePos += 360
			while(hingePos > 360):
				hingePos -= 360
			
			var closest = 0
			var closest_distance = abs(snapAngles[0] - hingePos)
			
			for i in range(1, len(snapAngles)):
				var distance = abs(snapAngles[i] - hingePos)
				#print('Distance distance: ', distance)
				if(distance < closest_distance):
					closest_distance = distance
					closest = snapAngles[i]
			
			if(closest == 360):
				closest = 0
			
			emit_signal("playSnapSound")
			_set_hinge_position(closest)
			
			emit_signal("onDeselectSignal", get_node("rotation_plane_body/body_mesh/RotationArea"))
			selected = false
