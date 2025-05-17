extends MultiMeshInstance3D

@export var instance_count := 100

@export var spawn_radius := 20.0
@export var mesh_to_use: Mesh
@export var material_to_use: Material

@export var antSpeed: float = .05
@export var wander_distance := 1
@export var wander_angle_deg := 60.0

@export var search_depth: int = 1

@export var backtracking := false 

var team 
var world_grid

var paths = [] 
var antData = [] 

func _ready():
	await get_tree().process_frame
	world_grid = get_parent().world_grid
	team = get_parent().team
	print(team)
	
	
	# Create and configure the MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	material_override = material_to_use
	self.multimesh = multimesh

	# Set transform for each instance (e.g. random spread)
	for i in instance_count:
		if i >= 1:
			continue
		#var pos = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * randf() * spawn_radius
		var pos = position
		var transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(i, transform)
		
		var offset_x = randf_range(-0.1, 0.1)
		var offset_z = randf_range(-0.1, 0.1)		
		antData.append({
			"position": pos, 
			"cell": Vector2i(0, 0),
			"path": [pos + Vector3(offset_x, 0, offset_z)],
			
			"carryingFood": false, 
			"backtracking": false,
			"targetingFood": false,

			"trail": [],
			"trailIndex": -1,
			"followingTrail": false,
		})

func get_random_index(arr: Array):
	if arr.is_empty():
		return -1
	return randi_range(0, arr.size() - 1)

func find_nearest_food(center_cell):
	var foodPositions = []
	var discoveredTrails = [] 

	for x in range(center_cell.x - search_depth, center_cell.x + search_depth + 1):
		for z in range(center_cell.y - search_depth, center_cell.y + search_depth + 1):
			var cell = Vector2i(x, z)
			if(!world_grid.grid.has(cell)):
				continue
			var entries = world_grid.get_entities_at_cell(cell)
			for entry in entries:
				if entry.type == "foodsource" and entry.has("position"):
					foodPositions.append(entry.position)
				elif entry.type == "foodTrail":
					discoveredTrails.append({"trailIndex": entry.trailIndex, "nodeIndex": entry.nodeIndex})
	var foodPos = null
	var trailIndex = null
	var nodeIndex = null
	if(discoveredTrails.size() > 0):
		var index = get_random_index(discoveredTrails)
		trailIndex = discoveredTrails[index].trailIndex
		nodeIndex = discoveredTrails[index].nodeIndex
	if(foodPositions.size() > 0):
		foodPos = foodPositions[get_random_index(foodPositions)]
	return {"foodPos": foodPos, "trailIndex": trailIndex, "nodeIndex": nodeIndex}

var trails = []
func add_path_to_grid(path): 
	var trail = []
	var trailIndex = trails.size()
	for node in path: 
		trail.append(to_global(node))
		# Add trail index here too
		world_grid.register_entity(to_global(node), {
			"type": "foodTrail", 
			"trailIndex": trailIndex, 
			"nodeIndex": trail.size() - 1,
			"team": team
		})
	trails.append({
		"path": trail,
		"value": 100
	})
	return trailIndex

# "position": pos, 
# "cell": Vector2i(0, 0),
# "path": [pos + Vector3(offset_x, 0, offset_z)],

# "carryingFood": true, 
# "backtracking": false,
# "targetingFood": false,

# "trail": [],
# "trailIndex": 0,
# "followingTrail": false,
func _physics_process(delta):
	for i in antData.size():
		var ant = antData[i]
		var trailIndex = ant.trailIndex
		
		if(ant.path.size() == 0):
			# Ant is at base
			ant.backtracking = false 
			if(ant.followingTrail and trailIndex != -1):
				ant.path.append(to_local(trails[trailIndex].path[0]))
			else:
				var offset_x = randf_range(-0.1, 0.1)
				var offset_z = randf_range(-0.1, 0.1)
				ant.path.append(Vector3(offset_x, 0, offset_z))
		elif(antData[i].path.size() >= 5):
			antData[i].backtracking = true 
		
		var path = ant.path 
		var pathLength = ant.path.size() 
		
		var trailLength = 0 
		if(trailIndex >= 0): 
			trailLength = trails[trailIndex].path.size()

		var currentPos:Vector3 = ant.position
		var targetPos:Vector3 = path[path.size() - 1]

		if(currentPos.distance_to(targetPos) < 0.1):
			# Ant reaches target
			 #or ant.path[pathLength - 1] == trails[trailIndex][trailLength - 1]
			if(ant.targetingFood): 
				# Ant reaches food
				ant.backtracking = true
				ant.carryingFood = true
				ant.targetingFood = false 
				ant.trailIndex = add_path_to_grid(antData[i].path)
				
			if(!ant.backtracking):
				if(ant.followingTrail):
					if(ant.path[pathLength - 1] == to_local(trails[trailIndex].path[trailLength - 1])):
						ant.backtracking = true
						ant.carryingFood = true
					else:
						# Add next path node in trail
						ant.path.append(to_local(trails[trailIndex].path[pathLength]))
				else: 
					# Wander to new target
					var forward = (targetPos - currentPos).normalized() 
					var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
					var angle_rad = deg_to_rad(angle_deg)
					
					var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
					var new_target = (currentPos + rotated_forward) * wander_distance
					ant.path.append(new_target)
			else: 
				# Backtrack
				ant.path.pop_back() 
		
		#var offset_x = randf_range(-0.075, 0.075)
		#var offset_z = randf_range(-0.05, 0.05)
		#var offset = Vector3(offset_x, 0, offset_z)
		#var direction = ((targetPos + offset) - currentPos).normalized()
		
		var direction = (targetPos - currentPos).normalized()
		var move_vector = direction * antSpeed * delta
		var new_pos = currentPos + move_vector
		
		var current_transform = multimesh.get_instance_transform(i)
		var target_basis = Basis().looking_at(direction, Vector3.UP)
		var current_basis = current_transform.basis
		var smoothed_basis = current_basis.slerp(target_basis, 0.2)  # 0.2 = smoothing factor

		var currentCell = world_grid.position_to_cell(to_global(new_pos))
		if(currentCell != ant.cell):
			# Ant moves to new cell in grid 
			if(!ant.backtracking):
				var search = find_nearest_food(currentCell)
				var trail = search.trailIndex
				var nodeIndex = search.nodeIndex
				var foodPos = search.foodPos

				if(trail != null and !ant.followingTrail):
					# Existing food trail found
					ant.trailIndex = trail
					ant.followingTrail = true
					for x in range(nodeIndex):
						ant.path.append(to_local(trails[trailIndex].path[x]))
					ant.path.resize(nodeIndex + 1)
					
				if(foodPos != null and !ant.followingTrail): 
					# Target found food
					var local = to_local(foodPos)
					ant.path.pop_back()
					ant.path.append(Vector3(local.x, ant.position.y, local.z))
					ant.targetingFood = true
					ant.followingTrail = true
				
			world_grid.unregister_entity(to_global(ant.position), {"type": "ant", "team": team, "index": i})
			ant.cell = world_grid.position_to_cell(to_global(new_pos))
			world_grid.register_entity(to_global(new_pos), {"type": "ant", "team": team, "index": i})
		ant.position = new_pos

		var transform = Transform3D(smoothed_basis, new_pos)
		multimesh.set_instance_transform(i, transform)

func spawn_ant_at(world_pos: Vector3):
	if(antData.size() >= instance_count):
		return 
		
	var index = antData.size()
	
	var pos = position
	var transform = Transform3D(Basis(), pos)
	multimesh.set_instance_transform(index, transform)
	
	var offset_x = randf_range(-0.1, 0.1)
	var offset_z = randf_range(-0.1, 0.1)		
	antData.append({
		"position": pos, 
		"cell": Vector2i(0, 0),
		"path": [pos + Vector3(offset_x, 0, offset_z)],
		
		"carryingFood": false, 
		"backtracking": false,
		"targetingFood": false,

		"trail": [],
		"trailIndex": -1,
		"followingTrail": false,
	})

	world_grid.register_entity(world_pos, {"type": "ant", "team": team, "index": index})
	
	
