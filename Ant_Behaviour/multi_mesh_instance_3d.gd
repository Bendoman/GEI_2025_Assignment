extends MultiMeshInstance3D

@export var instance_count := 20



@export var spawn_radius := 20.0
@export var mesh_to_use: Mesh
@export var material_to_use: Material

@export var antSpeed: float = .05
@export var wander_distance := 1
@export var wander_angle_deg := 60.0

@export var search_depth: int = 2

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
			"targetingFood": false,
			"followingTrail": false,
			"cell": Vector2i(0, 0),
			"trailIndex": 0
		})

func find_nearest_food(global_pos: Vector3):
	var foodPos
	var trail
	
	var center_cell = world_grid.position_to_cell(global_pos)
	for x in range(center_cell.x - search_depth, center_cell.x + search_depth + 1):
		for z in range(center_cell.y - search_depth, center_cell.y + search_depth + 1):
			var cell = Vector2i(x, z)
			if(!world_grid.grid.has(cell)):
				continue
			var entries = world_grid.get_entities_at_cell(cell)
			for entry in entries:
				if entry.type == "foodsource" and entry.has("position"):
					foodPos = entry.position
				elif entry.type == "foodTrail":
					trail = entry.path
					
	return {"foodPos": foodPos, "trail": trail}
	
func add_path_to_grid(path): 
	for node in path: 
		# Add trail index here too
		world_grid.register_entity(to_global(node), {"type": "foodTrail", "path": path})
		print(node)

func _physics_process(delta):
	for i in antData.size():
		if(antData[i].path.size() == 0): 
			antData[i].backtracking = false 
			var offset_x = randf_range(-0.1, 0.1)
			var offset_z = randf_range(-0.1, 0.1)
			antData[i].path.append(Vector3(offset_x, 0, offset_z))
		#elif(antData[i].path.size() >= 5):
			#antData[i].backtracking = true 
			
		var path = antData[i].path
		var currentPos:Vector3 = antData[i].position
		
		var targetPos:Vector3 = path[path.size() - 1]
		if(antData[i].followingTrail): 
			targetPos = path[antData[i].trailIndex]
			
		if(currentPos.distance_to(targetPos) < 0.1):
			if(antData[i].followingTrail): 
				antData[i].trailIndex += 1
					
			if(antData[i].targetingFood):
				antData[i].backtracking = true 
				antData[i].targetingFood = false 
				add_path_to_grid(antData[i].path)
				
			if not antData[i].backtracking and !antData[i].followingTrail:
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
		
		if !antData[i].backtracking and world_grid.position_to_cell(to_global(new_pos)) != antData[i].cell:
			var test = find_nearest_food(to_global(antData[i].position))	
			var foodPos = test.foodPos
			var trail = test.trail
			
			if(trail != null and !antData[i].followingTrail): 
				antData[i].path = trail
				antData[i].followingTrail = true
			elif(foodPos != null): 
				var local = to_local(foodPos)
				antData[i].path.pop_back()
				antData[i].path.append(Vector3(local.x, antData[i].position.y, local.z))
				antData[i].targetingFood = true
				
			world_grid.unregister_entity(to_global(antData[i].position), {"type": "ant", "index": i})
			antData[i].cell = world_grid.position_to_cell(to_global(new_pos))
			world_grid.register_entity(to_global(new_pos), {"type": "ant", "index": i})
			
		antData[i].position = new_pos
		
		
		
		
		var transform = Transform3D(smoothed_basis, new_pos)
		multimesh.set_instance_transform(i, transform)
