extends MultiMeshInstance3D

@export var instance_count := 1
@export var spawn_radius := 20.0
@export var mesh_to_use: Mesh
@export var material_to_use: Material

@export var antSpeed: float = .05
@export var wander_distance := 1
@export var wander_angle_deg := 60.0

@export var backtracking := false 
var world_grid

var paths = [] 
var antData = [] 

func _ready():
	await get_tree().process_frame
	world_grid = get_parent().world_grid
	
	# Create and configure the MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	material_override = material_to_use
	self.multimesh = multimesh

	# Set transform for each instance (e.g. random spread)
	for i in instance_count:
		#var pos = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * randf() * spawn_radius
		var pos = position
		var transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(i, transform)
		
		var offset_x = randf_range(-0.1, 0.1)
		var offset_z = randf_range(-0.1, 0.1)		
		antData.append({
			"position": pos, 
			"path": [pos + Vector3(offset_x, 0, offset_z)],
			"backtracking": false,
			"cell": Vector2i(0, 0)
		})

func _physics_process(delta):
	for i in antData.size():
		if(antData[i].path.size() == 0): 
			antData[i].backtracking = false 
			var offset_x = randf_range(-0.1, 0.1)
			var offset_z = randf_range(-0.1, 0.1)
			antData[i].path.append(Vector3(offset_x, 0, offset_z))
		elif(antData[i].path.size() >= 5):
			antData[i].backtracking = true 
			
		var path = antData[i].path
		var currentPos:Vector3 = antData[i].position
		var targetPos:Vector3 = path[path.size() - 1]
		
			
		if(currentPos.distance_to(targetPos) < 0.1):
			if not antData[i].backtracking:
				var forward = (targetPos - currentPos).normalized() 
		
				var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
				var angle_rad = deg_to_rad(angle_deg)
				
				var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
				var new_target = (currentPos + rotated_forward) * wander_distance
				
				antData[i].path.append(new_target)
			else: 
				# Backtrack 
				antData[i].path.pop_back()
				pass
			
		var direction = (targetPos - currentPos).normalized()
		var move_vector = direction * antSpeed * delta
		var new_pos = currentPos + move_vector
		
		var current_transform = multimesh.get_instance_transform(i)
		var target_basis = Basis().looking_at(direction, Vector3.UP)
		var current_basis = current_transform.basis
		var smoothed_basis = current_basis.slerp(target_basis, 0.2)  # 0.2 = smoothing factor
		
		#world_grid.unregister_entity(to_global(antData[i].position), {"type": "ant", "position": to_global(new_pos)} )
		antData[i].position = new_pos
		
		if world_grid.position_to_cell(to_global(new_pos)) != antData[i].cell:
			antData[i].cell = world_grid.position_to_cell(to_global(new_pos))
			print('Chaning cells to %s' % antData[i].cell)
		
		
		#world_grid.register_entity(to_global(new_pos), {"type": "ant", "position": to_global(new_pos)})
		
		var transform = Transform3D(smoothed_basis, new_pos)
		multimesh.set_instance_transform(i, transform)
