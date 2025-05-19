extends MultiMeshInstance3D

@export var instance_count := 101

@export var spawn_radius := 20.0
@export var mesh_to_use: Mesh
@export var material_to_use: Material

@export var ant_speed: float = .35
@export var wander_distance := 1
@export var wander_angle_deg := 60.0

@export var search_depth: int = 1 
@export var consumptionRate: int = 1
@onready var ant_renderer = $"../AntRenderer"

@export var backtracking := false 
@onready var carried_food_renderer = $"../CarriedFoodRenderer"

var team 
var world_grid
var trails

var paths = [] 
var ant_data = [] 
var base
func _ready():
	await get_tree().process_frame
	base = get_parent() 
	world_grid = get_parent().world_grid
	team = get_parent().team
	trails = ant_renderer.trails
	#print_debug(team)
	
	# Create red material
	var red_material := StandardMaterial3D.new()
	red_material.albedo_color = Color(1.0, 0.0, 0.0)  # Red

	# Create orange material
	var orange_material := StandardMaterial3D.new()
	orange_material.albedo_color = Color(1.0, 0.5, 0.0)  # Orange
	
	# Create and configure the MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count

	if(team == 1):
		material_override = red_material
	else: 
		material_override = orange_material
	self.multimesh = multimesh

	# Set transform for each instance (e.g. random spread)
	for i in instance_count:
		#return
		var offset_x = randf_range(-0.1, 0.1)
		var offset_z = randf_range(-0.1, 0.1)	
		
		if(team == 0):
			return
		else:
			offset_x = -0.1
			offset_z = 0.1
		if i >= 1:
			continue
		base.increaseWarriorCount()
			
		#var pos = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * randf() * spawn_radius
		var pos = position
		var transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(i, transform)
		
	
		ant_data.append({
			"position": pos, 
			"global_position": to_global(pos),

			"cell": Vector2i(0, 0),
			"path": [pos + Vector3(offset_x, 0, offset_z)],
			
			"backtracking": false,
			"targetingAnt": null,

			"trail": [],
			"trail_index": -1,
			"following_trail": false
		})

func removeTrail(index): 
	trails[index] = null 
	
func add_path_to_grid(path, antIndex): 
	var trail = []
	var cells = []
	
	var trail_index = trails.size()
	for i in range(trails.size()):
		if trails[i] == null:
			trail_index = i
			break
	
	for node in path: 
		# Add trail index here too
		trail.append(to_global(node))
		var cell = world_grid.position_to_cell(to_global(node))
		cells.append(cell)
		world_grid.register_entity(cell, {
			"type": "enemyTrail", 
			"trail_index": trail_index, 
			"nodeIndex": trail.size() - 1,
			"team": team
		})
	#print_debug("Added path: ", path, "\n to trail: ", trail)
	var added = false
	
	var value = {
		"path": trail,
		"value": 100,
		"assignedAnts": 0,
		"cells": cells,
	}
	if(trail_index == trails.size()):
		trails.append(value)
	else: 
		trails[trail_index] = value
	#print(trails)
	#print_debug(world_grid.grid)
	return trail_index

func remove_trail_from_grid(index): 
	for i in range(trails[index].path.size()):
		var node = trails[index].path[i]
		#print_debug("node index: ", i)
		var cell = trails[index].cells[i]
		#print(cell)
		world_grid.unregister_entity(cell, {
			"type": "foodTrail", 
			"trail_index": index, 
			"nodeIndex": i,
			"team": team
		})

func get_random_index(arr: Array):
	if arr.is_empty():
		return -1
	return randi_range(0, arr.size() - 1)
	
func find_nearest_food(center_cell):
	var foodPositions = []
	var discoveredTrails = [] 
	var workers = [] 

	for x in range(center_cell.x - search_depth, center_cell.x + search_depth + 1):
		for z in range(center_cell.y - search_depth, center_cell.y + search_depth + 1):
			var cell = Vector2i(x, z)
			if(!world_grid.grid.has(cell)):
				continue
			var entries = world_grid.get_entities_at_cell(cell)
			for entry in entries:
				if entry.type == "ant" and entry.team != team:
					print(entry.team)
					workers.append(entry)
					
				if(entry.has("team") and entry.team != team):
					continue
					
				if entry.type == "foodsource" and entry.has("position"):
					foodPositions.append(entry)
				elif entry.type == "foodTrail":
					#print_debug(entry)
					discoveredTrails.append({"trail_index": entry.trail_index, "nodeIndex": entry.nodeIndex, "source": entry.source})
	
	var discoveredEnemyWorker = null 


	var discoveredTrail
	if(discoveredTrails.size() > 0):
		var index = get_random_index(discoveredTrails)
		discoveredTrail = discoveredTrails[index]
	if(workers.size() > 0):
		var index = get_random_index(workers)
		discoveredEnemyWorker = workers[index]
	
	return {"discoveredEnemyWorker": discoveredEnemyWorker, "discoveredTrail": discoveredTrail}
	#return {"foodPos": foodPos, "trail_index": trail_index, "nodeIndex": nodeIndex, "trailSource": trailSource}


func _physics_process(delta):
	for i in ant_data.size():
		var ant = ant_data[i]
		var trail_index = ant.trail_index
		
		if(ant.path.size() == 0):
			# Ant is at base
			ant.backtracking = false 
			ant.following_trail = false
			ant.trail_index = -1
			trail_index = -1

			var offset_x = randf_range(-0.1, 0.1)
			var offset_z = randf_range(-0.1, 0.1)
			ant.path.append(Vector3(offset_x, 0, offset_z))
		elif(ant_data[i].path.size() >= 5):
			ant_data[i].backtracking = true 
		
		var path = ant.path 
		var pathLength = ant.path.size() 
		
		var trailLength = 0 
		if(trail_index >= 0): 
			if(trails[trail_index] == null):
				trail_index = -1
				ant.trail_index = -1
				ant.following_trail = false
			else:
				trailLength = trails[trail_index].path.size()

		var currentPos:Vector3 = ant.position
		var targetPos:Vector3 = path[path.size() - 1]
		if(trail_index >= 0 and ant.food_source != null and ant.food_source.food_left <= 0):
			# Food saturated 
			ant.trail_index = -1
			ant.following_trail = false 
			ant.backtracking = true
			ant.food_source = null

		if(currentPos.distance_to(targetPos) < 0.1):
			# Ant reaches target
			if(ant.targetingAnt != null):
				if(currentPos.distance_to(to_local(ant.targetingAnt.global_position)) < 0.1):
					print('caught ant')
					ant.targetingAnt.dead = true
					ant.targetingAnt = null
					ant.backtracking = true
				else: 
					#ant.path.append(to_local(ant.targetingAnt.global_position))
					#ant.path.append(ant.targetingAnt.global_position)
					#ant.path.append(to_local(ant.targetingAnt.path[ant.targetingAnt.path.size() - 1]))
					#ant.path.append(ant.targetingAnt.path[ant.targetingAnt.path.size() - 1])
					print('process next pursue target')
					var start = ant.path[0]
					ant.path = [] 
					ant.path.append(start)
					var forward = (ant.targetingAnt.global_position - ant.global_position).normalized()
					var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
					var angle_rad = deg_to_rad(angle_deg)
					
					var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
					var new_target = (ant.position + rotated_forward) * wander_distance
					ant.path.append(new_target)
					
			if(!ant.backtracking):
				if(ant.following_trail):
					if(ant.path[pathLength - 1] == to_local(trails[trail_index].path[trailLength - 1])):
						# Ant reaches food from trail
						ant.backtracking = true
					else:
						# Add next path node in trail
						ant.path.append(to_local(trails[trail_index].path[pathLength]))
						
					if(ant.food_source.food_left == 0):
						# Food saturated 
						#print_debug("pre removing trail from grid")
						remove_trail_from_grid(trail_index)
						var pos = Vector3(ant.food_source.position.x, 0, ant.food_source.position.z)
						world_grid.unregister_entity(ant.food_source.cell, {"type": "foodsource", "position": pos, "food_left": ant.food_source.food_left})
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
				
		var direction = (targetPos - currentPos).normalized()
		var move_vector = direction * ant_speed * delta
		var new_pos = currentPos + move_vector
		
		var current_transform = multimesh.get_instance_transform(i)
		var target_basis = Basis().looking_at(direction, Vector3.UP)
		var current_basis = current_transform.basis
		var smoothed_basis = current_basis.slerp(target_basis, 0.2)  # 0.2 = smoothing factor

		var currentCell = world_grid.position_to_cell(to_global(new_pos))
		if(currentCell != ant.cell):
			# Ant moves to new cell in grid 
			var search = find_nearest_food(currentCell)
			
			var trail
			var nodeIndex
			var trailSource
			var discoveredTrail = search.discoveredTrail
			var discoveredEnemyWorker = search.discoveredEnemyWorker

			var enemyAnt
			#if(discoveredEnemyWorker != null and ant.path.size() > 0 and ant.targetingAnt == null):
				##print(base.getAnt(discoveredEnemyWorker.team, discoveredEnemyWorker.index, "worker"))
				#enemyAnt = base.getAnt(discoveredEnemyWorker.team, discoveredEnemyWorker.index, "worker")
				##print("Warrior detected, ", enemyAnt)
				#enemyAnt.fleeing = [team, i]
				#ant.following_trail = false 
				#ant.trail_index = -1
				#ant.targetingAnt = enemyAnt
				#var start = ant.path[0]
				#ant.path = [] 
				#ant.path.append(start)
				#ant.path.append(to_local(enemyAnt.global_position))
				
			if(discoveredTrail):
				trail = discoveredTrail.trail_index
				nodeIndex = discoveredTrail.nodeIndex
				trailSource = discoveredTrail.source
				
			if(trail != null and !ant.following_trail and ant.targetingAnt == null):
				# Existing food trail found
				ant.trail_index = trail
				ant.following_trail = true
				if(trails[ant.trail_index] != null):
					trails[ant.trail_index].assignedAnts += 1
					ant.path = [] 
					ant.food_source = trailSource
					var index = 0 
					while true: 
						ant.path.append(to_local(trails[ant.trail_index].path[index]))
						index += 1
						if index > nodeIndex:
							break
					ant.path.resize(nodeIndex + 1)	
			world_grid.unregister_entity(ant.cell, {"type": "warrior", "team": team, "index": i})
			ant.cell = world_grid.position_to_cell(to_global(new_pos))
			world_grid.register_entity(ant.cell, {"type": "warrior", "team": team, "index": i})

		
		ant.position = new_pos
		ant.global_position = to_global(ant.position)

		var transform = Transform3D(smoothed_basis, new_pos)
		multimesh.set_instance_transform(i, transform)

func spawn_ant(): 
	if(ant_data.size() >= instance_count):
		return 
		
	base.increaseWarriorCount()
	#var pos = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * randf() * spawn_radius
	var index = ant_data.size()
	
	var pos = position
	var transform = Transform3D(Basis(), pos)
	multimesh.set_instance_transform(index, transform)
	
	var offset_x = randf_range(-0.1, 0.1)
	var offset_z = randf_range(-0.1, 0.1)		
	ant_data.append({
		"position": pos, 
		"global_position": to_global(pos),	
		"cell": Vector2i(0, 0),
		"path": [pos + Vector3(offset_x, 0, offset_z)],
		
		"backtracking": false,
		"targetingAnt": null,

		"trail": [],
		"trail_index": -1,
		"following_trail": false
	})
