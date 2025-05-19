extends MultiMeshInstance3D

@export var instance_count := 10

@export var spawn_radius := 20.0
@export var mesh_to_use: Mesh
@export var material_to_use: Material

var ant_speed: float = .25
@export var wander_distance := 1
@export var wander_angle_deg := 60.0



@export var search_depth: int = 1 
@export var consumptionRate: int = 1
@onready var warrior_ant_renderer = $"../WarriorAntRenderer"

@export var backtracking := false 
@onready var carried_food_renderer = $"../CarriedFoodRenderer"

var max_warriors = 1
var currentWarriors = 0

var team 
var world_grid

var paths = [] 
var ant_data = [] 
var base
func _ready():
	await get_tree().process_frame
	base = get_parent() 
	world_grid = get_parent().world_grid
	team = get_parent().team
	#print_debug(team)
	
	
	# Create navy material
	var navy_material := StandardMaterial3D.new()
	navy_material.albedo_color = Color(0.0, 0.0, 0.5)  # Navy

	# Create black material
	var black_material := StandardMaterial3D.new()
	black_material.albedo_color = Color(0.0, 0.0, 0.0)  # Black

	# Create and configure the MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	
	if(team == 1):
		material_override = black_material
	else: 
		material_override = navy_material
	
	self.multimesh = multimesh

	# Set transform for each instance (e.g. random spread)
	for i in instance_count:
		if i >= 3:
			continue
			
		var offset_x = randf_range(-0.1, 0.1)
		var offset_z = randf_range(-0.1, 0.1)		
		if(team == 0):
			offset_x = 0.1
			offset_z = 0.1
		else:
			offset_x = -0.1
			offset_z = 0.1
			return
			
		base.increaseAntCount()
			
		#var pos = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * randf() * spawn_radius
		var pos = position
		var transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(i, transform)
		

		ant_data.append({
			"position": pos, 
			"global_position": to_global(pos),
			"cell": Vector2i(0, 0),
			"path": [pos + Vector3(offset_x, 0, offset_z)],
			"dead": false,

			"carrying_food": false, 
			"backtracking": false,
			"targeting_food": false,
			"fleeing": null,
			"fleeingBool": false,
			
			"reporting_enemy": false, 
			
			"trail": [],
			"trail_index": -1,
			"following_trail": false,
			
			"source": null,
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
					workers.append(entry)
				
				if(entry.has("team") and entry.team != team):
					continue
					
				if entry.type == "foodsource" and entry.has("position"):
					foodPositions.append(entry)
				elif entry.type == "foodTrail":
					discoveredTrails.append({"trail_index": entry.trail_index, "nodeIndex": entry.nodeIndex, "source": entry.source})

	var foodPos = null
	var discoveredTrail = null
	var discoveredEnemyWorker = null 
	if(discoveredTrails.size() > 0):
		var index = get_random_index(discoveredTrails)
		discoveredTrail = discoveredTrails[index]
	if(foodPositions.size() > 0):
		foodPos = foodPositions[get_random_index(foodPositions)]
	if(workers.size() > 0):
		var index = get_random_index(workers)
		discoveredEnemyWorker = workers[index]
		
	return {"foodPos": foodPos, "discoveredTrail": discoveredTrail, "discoveredEnemyWorker": discoveredEnemyWorker}
	#return {"foodPos": foodPos, "trail_index": trail_index, "nodeIndex": nodeIndex, "trailSource": trailSource}

var trails = []
func removeTrail(index): 
	trails[index] = null 
	
func add_path_to_grid(path, source): 
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
		world_grid.register_entity(to_global(node), {
			"type": "foodTrail", 
			"trail_index": trail_index, 
			"nodeIndex": trail.size() - 1,
			"team": team,
			"source": source
		}, cell)
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
	#print("removing trail: ", trails[index])
	for i in range(trails[index].path.size()):
		var node = trails[index].path[i]
		#print_debug("node index: ", i)
		var cell = trails[index].cells[i]
		#print(cell)
		world_grid.unregister_entity(node, {
			"type": "foodTrail", 
			"trail_index": index, 
			"nodeIndex": i,
			"team": team
		}, cell)
	#print_debug("Removing trail ", world_grid.grid)





# "position": pos, 
# "cell": Vector2i(0, 0),
# "path": [pos + Vector3(offset_x, 0, offset_z)],

# "carrying_food": true, 
# "backtracking": false,
# "targeting_food": false,

# "trail": [],
# "trail_index": 0,
# "following_trail": false,
func _physics_process(delta):
	for i in ant_data.size():
		var ant = ant_data[i]
		var trail_index = ant.trail_index
		
		if(ant.dead):
			world_grid.unregister_entity(to_global(ant.position), {"type": "ant", "team": team, "index": i}, ant.cell)
			continue
		
		if(ant.fleeing != null and !ant.fleeingBool):
			ant.fleeingBool = true
			var enemyAnt = base.getAnt(ant.fleeing[0], ant.fleeing[1], "warrior")
			ant.following_trail = false
			ant.backtracking = false 
			ant.targeting_food = false 
			ant.trail_index = -1	
			var forward = (ant.global_position - enemyAnt.global_position).normalized()
			var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
			var angle_rad = deg_to_rad(angle_deg)
			
			var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
			var new_target = (ant.position + rotated_forward) * wander_distance
			ant.path.append(new_target)
					
			print("Ant fleeing from: ", enemyAnt)

			#world_grid.unregister_entity(to_global(ant.position), {"type": "ant", "team": team, "index": i}, ant.cell)
			#continue
		
		if(ant.path.size() == 0):
			# Ant is at base
			#print("ant at base: ", i)
			#if(ant.reporting_enemy):
				#warrior_ant_renderer.spawn_ant()
				
			if(ant.reporting_enemy):
				if(currentWarriors < max_warriors):
					warrior_ant_renderer.spawn_ant()
					currentWarriors += 1
				
			if(ant.carrying_food):
				base.incrementFoodLevel(consumptionRate)
				#print("Food returned to base: ", base.foodLevel)
			ant.carrying_food = false
			ant.reporting_enemy = false
			carried_food_renderer.removeCarriedFood(i)
			
			ant.backtracking = false 
			if(ant.following_trail and trail_index != -1):
				ant.path.append(to_local(trails[trail_index].path[0]))
			else:
				var offset_x = randf_range(-0.1, 0.1)
				var offset_z = randf_range(-0.1, 0.1)
				ant.path.append(Vector3(offset_x, 0, offset_z))
		elif(ant_data[i].path.size() >= 5 and !ant.following_trail):
			ant_data[i].backtracking = true 
		
		var path = ant.path 
		var pathLength = ant.path.size() 
		
		var trailLength = 0 
		if(trail_index >= 0): 
			if(trails[trail_index] == null):
				trail_index = -1
				ant.trail_index = -1
				ant.following_trail = false
				ant.food_source = null
			else:
				trailLength = trails[trail_index].path.size()

		var currentPos:Vector3 = ant.position
		var targetPos:Vector3 = path[path.size() - 1]
		if(trail_index >= 0 and ant.food_source != null and ant.food_source.food_left <= 0):
			#print_debug('saturated')
			# Food saturated 
			if(ant.food_source.food_left <= 0):
				# Food saturated 
				#print_debug("pre removing trail from grid")
				remove_trail_from_grid(trail_index)
				#print(ant.food_source)
				var pos = Vector3(ant.food_source.position.x, 0, ant.food_source.position.z)
				world_grid.unregister_entity(global_position, {"type": "foodsource", "position": pos, "food_left": ant.food_source.food_left}, ant.food_source.cell)
				
						
			trails[trail_index].assignedAnts -= 1
			if(trails[trail_index].assignedAnts <= 0):
				removeTrail(trail_index)
				#print("Trails: ", trails)
				
			ant.trail_index = -1
			ant.following_trail = false 
			ant.backtracking = true
			ant.food_source = null

		if(currentPos.distance_to(targetPos) < 0.1):
			#if(ant.has("source") and ant.food_source != null):
				#print(ant.food_source.food_left)
			# Ant reaches target
			 #or ant.path[pathLength - 1] == trails[trail_index][trailLength - 1]
			if(ant.targeting_food and ant.food_source != null): 
				# Ant reaches newly found food
				ant.backtracking = true
				ant.carrying_food = true
				carried_food_renderer.addCarriedFood(i)

				ant.targeting_food = false 
				ant.trail_index = add_path_to_grid(ant.path, ant.food_source)
				ant.following_trail = true
				trails[ant.trail_index].assignedAnts += 1
				trails[ant.trail_index].value -= consumptionRate
				ant.food_source.food_left -= consumptionRate
				
			if(!ant.backtracking and !ant.fleeingBool):
				if(ant.following_trail):
					if(ant.path[pathLength - 1] == to_local(trails[trail_index].path[trailLength - 1])):
						# Ant reaches food from trail
						ant.backtracking = true
						ant.carrying_food = true
						carried_food_renderer.addCarriedFood(i)
						trails[trail_index].value -= consumptionRate
						ant.food_source.food_left -= consumptionRate
						#print_debug(ant.food_source.food_left)
					else:
						# Add next path node in trail
						ant.path.append(to_local(trails[trail_index].path[pathLength]))
				else: 
					# Wander to new target
					var forward = (targetPos - currentPos).normalized() 
					var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
					var angle_rad = deg_to_rad(angle_deg)
					
					var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
					var new_target = (currentPos + rotated_forward) * wander_distance
					ant.path.append(new_target)
			elif(!ant.fleeingBool): 
				# Backtrack
				ant.path.pop_back() 
			elif(ant.fleeingBool):
				print('process next flee target')
				var enemyAnt = base.getAnt(ant.fleeing[0], ant.fleeing[1], "warrior")	
				var forward = (ant.global_position - enemyAnt.global_position).normalized()
				var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
				var angle_rad = deg_to_rad(angle_deg)
				
				var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
				var new_target = (ant.position + rotated_forward) * wander_distance
				ant.path.append(new_target)
		
		#var offset_x = randf_range(-0.075, 0.075)
		#var offset_z = randf_range(-0.05, 0.05)
		#var offset = Vector3(offset_x, 0, offset_z)
		#var direction = ((targetPos + offset) - currentPos).normalized()
		
		var direction = (targetPos - currentPos).normalized()
		var move_vector = direction * ant_speed * delta
		var new_pos = currentPos + move_vector
		
		var current_transform = multimesh.get_instance_transform(i)
		var target_basis = Basis().looking_at(direction, Vector3.UP)
		var current_basis = current_transform.basis
		var smoothed_basis = current_basis.slerp(target_basis, 0.2)  # 0.2 = smoothing factor

		var currentCell = world_grid.position_to_cell(to_global(new_pos))
		if(currentCell != ant.cell and !ant.reporting_enemy):
			# Ant moves to new cell in grid 
			var search = find_nearest_food(currentCell)
			var trail
			var nodeIndex
			var trailSource
			var discoveredTrail = search.discoveredTrail
			var discoveredEnemyWorker = search.discoveredEnemyWorker
			var enemyAnt
			
			if(discoveredEnemyWorker != null):
				#print(base.getAnt(discoveredEnemyWorker.team, discoveredEnemyWorker.index, "worker"))
				enemyAnt = base.getAnt(discoveredEnemyWorker.team, discoveredEnemyWorker.index, "worker")
				
			if(discoveredTrail != null and !ant.carrying_food and !ant.reporting_enemy):
				trail = discoveredTrail.trail_index
				nodeIndex = discoveredTrail.nodeIndex
				trailSource = discoveredTrail.source

			var foodPos
			var source = search.foodPos
			if(source != null):
				foodPos = search.foodPos.position
				ant.food_source = source
				
			if(enemyAnt != null and ant.path.size() > 1): 
				# Found enemey ant
				#ant.path.append(to_local(enemyAnt.global_position))
				#print("Path to enemey found: ", ant, ant.backtracking, ant.reporting_enemy)
				if(currentWarriors < max_warriors):
					if(ant.path.size() > 1):
						ant.path.pop_back()
					ant.backtracking = true
					ant.reporting_enemy = true
					ant.targeting_food = false
				
			if(trail != null and !ant.following_trail and !ant.reporting_enemy):
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
					ant.backtracking = false
					#print_debug("reseting backtracking here")
			elif(foodPos != null and !ant.following_trail and !ant.reporting_enemy): 
				#print_debug("in here")
				# Target found food
				var local = to_local(foodPos)
				ant.path.pop_back()
				ant.path.append(Vector3(local.x, ant.position.y, local.z))
				ant.targeting_food = true
				ant.food_source = source
				
		if(currentCell != ant.cell):
			world_grid.unregister_entity(to_global(ant.position), {"type": "ant", "team": team, "index": i}, ant.cell)
			ant.cell = world_grid.position_to_cell(to_global(new_pos))
			world_grid.register_entity(to_global(new_pos), {"type": "ant", "team": team, "index": i}, ant.cell)

		
		ant.position = new_pos
		ant.global_position = to_global(ant.position)

		var transform = Transform3D(smoothed_basis, new_pos)
		multimesh.set_instance_transform(i, transform)

func spawn_ant(): 
	if(ant_data.size() >= instance_count):
		return 
		
	base.increaseAntCount()
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
		"dead": false,
		"carrying_food": false, 
		"backtracking": false,
		"targeting_food": false,
		"fleeing": null,	
		"fleeingBool": false,
		
		"reporting_enemy": false, 
		
		"trail": [],
		"trail_index": -1,
		"following_trail": false,
		
		"source": null,
	})

func spawn_ant_at(world_pos: Vector3):
	if(ant_data.size() >= instance_count):
		return 
		
	base.increaseAntCount()
		
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
		"dead": false,
		
		"carrying_food": false, 
		"backtracking": false,
		"targeting_food": false,
		"fleeing": null,
		"fleeingBool": false,
		
		"reporting_enemy": false, 
		
		"trail": [],
		"trail_index": -1,
		"following_trail": false,
		
		"source": null,
	})

	world_grid.register_entity(world_pos, {"type": "ant", "team": team, "index": index})
	
	
