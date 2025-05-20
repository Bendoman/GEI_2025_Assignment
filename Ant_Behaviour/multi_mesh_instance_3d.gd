extends MultiMeshInstance3D

const AntData = preload("res://ant_data.gd")

# Multimesh properties
@export var mesh_to_use: Mesh
@export var instance_count = 1000
@export var starting_count = 100

# Wandering
@export var ant_speed: float = 1
@export var wander_distance := 1
@export var wander_angle_deg := 60.0

# Grid searching
@export var search_depth: int = 3
@export var consumptionRate: int = 1
@export var search_distance: int = 2

# Renderer references
@onready var warrior_ant_renderer = $"../WarriorAntRenderer"
@onready var carried_food_renderer = $"../CarriedFoodRenderer"
var ant_renderers = []
var warrior_renderers = [] 

var base
var team 
var world_grid
# var ant_mass = 1
var max_warriors = 1
var current_warriors = 0

var paths = [] 
var ant_data = [] 

var colors = [
	Color(0.0, 0.0, 0.5), 
	Color(0.0, 0.0, 0.0)
]

func _ready():
	await get_tree().process_frame
	
	base = get_parent() 
	team = get_parent().team
	world_grid = get_parent().world_grid
	ant_renderers = get_parent().ant_renderers
	warrior_renderers = get_parent().warrior_renderers
	
	# Create and configure the MultiMesh
	var material = StandardMaterial3D.new()
	material.albedo_color = colors[team]

	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	# Need to be changed
	material_override = material
	self.multimesh = multimesh

	# Set initial transform for each instance
	for i in instance_count:
		if i >= starting_count:
			break

		var transform = Transform3D(Basis(), position)
		multimesh.set_instance_transform(i, transform)
		
		var ant = AntData.new() 
		ant.team = team 
		ant.position = position
		ant.global_position = to_global(position)
		ant.cell = world_grid.position_to_cell(ant.global_position)

		world_grid.register_entity(ant.cell, {"type": "ant", "team": team, "index": i, "global_position": ant.global_position})

		ant_data.append(ant)		
		base.increaseAntCount()


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
					
				if entry.type == "food_source" and entry.has("position"):
					foodPositions.append(entry)
				elif entry.type == "foodTrail":
					discoveredTrails.append({"trail_index": entry.trail_index, "nodeIndex": entry.nodeIndex, "source": entry.source})

	var foodPos = null
	var discoveredTrail = null
	var discoveredEnemyWorker = null 
	if(discoveredTrails.size() > 0):
		var index = Utils.get_random_index(discoveredTrails)
		discoveredTrail = discoveredTrails[index]
	if(foodPositions.size() > 0):
		foodPos = foodPositions[Utils.get_random_index(foodPositions)]
	if(workers.size() > 0):
		var index = Utils.get_random_index(workers)
		discoveredEnemyWorker = workers[index]
		
	return {"foodPos": foodPos, "discoveredTrail": discoveredTrail, "discoveredEnemyWorker": discoveredEnemyWorker}
	#return {"foodPos": foodPos, "trail_index": trail_index, "nodeIndex": nodeIndex, "trailSource": trailSource}

var trails = []
func removeTrail(index): 
	trails[index] = null 

func new_add_path_to_grid(path, source): 
	var trail = []
	var cells = []
	
	var trail_index = trails.size()
	for i in range(trails.size()):
		if trails[i] == null:
			trail_index = i
			break
	
	for node in path: 
		# Add trail index here too
		trail.append(node)
		var cell = world_grid.position_to_cell(to_global(node))
		cells.append(cell)
		world_grid.register_entity(cell, {
			"type": "foodTrail", 
			"trail_index": trail_index, 
			"nodeIndex": trail.size() - 1,
			"team": team,
			"source": source
		})
	
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
		
	return trail_index

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
		world_grid.register_entity(cell, {
			"type": "foodTrail", 
			"trail_index": trail_index, 
			"nodeIndex": trail.size() - 1,
			"team": team,
			"source": source
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
		var cell = trails[index].cells[i]

		world_grid.unregister_entity(cell, {
			"type": "foodTrail", 
			"trail_index": index, 
			"nodeIndex": i,
			"team": team
		})

func remove_food_source_from_grid(food_source): 
	world_grid.unregister_entity(food_source.cell, food_source)

func handle_saturated_foodsource(trail_index, food_source): 
	remove_trail_from_grid(trail_index)
	remove_food_source_from_grid(food_source)

func generate_wander_target(currentPos, targetPos):
	var forward = (targetPos - currentPos).normalized() 
	var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
	var angle_rad = deg_to_rad(angle_deg)
	
	var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
	var new_target = (currentPos + rotated_forward) * wander_distance
	return new_target

func generate_initial_target(): 
	var offset_x = randf_range(-0.1, 0.1)
	var offset_z = randf_range(-0.1, 0.1)

	if(team == 0):
		offset_x = .1
		offset_z = .1
	else: 
		offset_x = -.1
		offset_z = .1


	return Vector3(offset_x, 0, offset_z)

func calculate_new_transform(currentPos, targetPos, current_transform, delta): 
		var to_target = targetPos - currentPos
		var distance_to_target = to_target.length()
		# Clamp movement to remaining distance
		var max_move_distance = ant_speed * delta
		var move_distance = min(distance_to_target, max_move_distance)
		
		var direction = to_target.normalized()
		var move_vector = direction * move_distance
		
		var new_pos = currentPos + move_vector
		var new_global = to_global(new_pos)

		var target_basis = Basis().looking_at(direction, Vector3.UP)
		var current_basis = current_transform.basis
		var smoothed_basis = current_basis.slerp(target_basis, 0.2)
		
		return [Transform3D(smoothed_basis, new_pos), new_global, new_pos]

func a_physics_process(delta): 
	for i in ant_data.size(): 
		var ant = ant_data[i]
		var path = ant.path 
		var path_size = ant.path.size() 
		var trail_index = ant.trail_index
		
		if(ant.dead): 
			pass
		
		# Unregister foodsource and trail from grid if not already done 
		if(ant.food_source != null and ant.food_source.food_left <= 0):
			if(trails[ant.trail_index] != null):
				handle_saturated_foodsource(ant.trail_index, ant.food_source)
				removeTrail(ant.trail_index)
			ant.trail_index = -1 
			ant.food_source == null
			ant.backtracking = true 
			ant.following_trail = false 
		
		if(ant.path.size() == 0): 
			# Ant is at base 
			if(ant.carrying_food):
				base.incrementFoodLevel(consumptionRate)
			ant.carrying_food = false
			ant.reporting_enemy = false
			carried_food_renderer.removeCarriedFood(i)

			ant.backtracking = false 
			print("resetting here")
			
			if(ant.following_trail and trail_index != -1):
				ant.path.append(to_local(trails[trail_index].path[path_size]))
			else:
				ant.path.append(generate_initial_target())
		elif(path_size >= 5 and !ant.following_trail):
			# Return from wander that didn't find food
			ant_data[i].backtracking = true 
			
		var trail_length = 0
		if(trail_index >= 0): 
			trail_length = trails[trail_index].path.size()

		var currentPos:Vector3 = ant.position
		var targetPos:Vector3 = path[path.size() - 1]
		
		# Calculate steering
		if(currentPos.distance_to(targetPos) < 0.1):
			if(ant.fleeing_from != null): 
				# Fleeing from warrior
				pass
			elif(ant.targeting_food): 
				# Ant reaches newly found food 
				print("Reached targeted food source")
				ant.backtracking = true 
				ant.following_trail = true
				ant.targeting_food = false 
				
				ant.carrying_food = true 
				carried_food_renderer.addCarriedFood(i)
				ant.trail_index = add_path_to_grid(ant.path, ant.food_source)
				trails[ant.trail_index].assignedAnts += 1
				ant.food_source.food_left -= consumptionRate
			elif(ant.backtracking):
				ant.path.pop_back() 
			elif(ant.following_trail):
				# Follow trail
				if(ant.path[path_size - 1] == trails[trail_index].path[trail_length - 1]):
					# Ant reaches food from trail
					print("Reached food from trail")
				else:
					# Move to next node in path
					ant.path.append(to_local(trails[trail_index].path[path_size]))
			else: # Wandering 
				ant.path.append(generate_wander_target(currentPos, targetPos))
			
		var currentCell = world_grid.position_to_cell(to_global(currentPos))
		if(currentCell != ant.cell and !ant.reporting_enemy and ant.fleeing_from == null):
			# Ant moves to new movement cell in grid
			ant.movement_cell = currentCell
			
			var scan_result = scan_world_grid(ant.cell, ant.global_position)
			var enemy_ant = scan_result.enemy_ant
			var food_source = scan_result.food_source
			var discovered_trail = scan_result.discovered_trail
		
			if(discovered_trail != null and !ant.carrying_food and !ant.followingTrail and !ant.reporting_enemey): 
				pass
			elif(food_source != null and !ant.targeting_food and !ant.following_trail and !ant.reporting_enemy): 
				print("Targeting food source")
				var local = to_local(food_source.global_position)
				ant.path.pop_back() 
				ant.path.append(Vector3(local.x, ant.position.y, local.z))
				ant.targeting_food = true
				ant.food_source = food_source

		# Perform movement
		var transform = calculate_new_transform(currentPos, targetPos, multimesh.get_instance_transform(i), delta)
		var new_global = transform[1]
		
		if(currentCell != ant.cell):
		# if(currentCell != ant.cell):
			world_grid.unregister_entity({"type": "ant", "team": team, "index": i, "global_position": ant.previous_global}, ant.cell)
			ant.cell = world_grid.position_to_cell(new_global)
			world_grid.register_entity(ant.cell, {"type": "ant", "team": team, "index": i, "global_position": new_global})
			ant.previous_global = new_global
		
		ant.position = transform[2]
		ant.global_position = new_global
		multimesh.set_instance_transform(i, transform[0])

func scan_world_grid(center_cell, ant_position): 
	var enemy_ants = [] 
	var food_sources = [] 
	var discovered_trails = [] 
	
	for x in range(center_cell.x - search_depth, center_cell.x + search_depth + 1):
		for z in range(center_cell.y - search_depth, center_cell.y + search_depth + 1):
			var cell = Vector2i(x, z)
			if(!world_grid.grid.has(cell)):
				continue

			var entries = world_grid.get_entities_at_cell(cell)
			for entry in entries:
				if(entry.type == "ant" and entry.team != team):
					var found_ant = ant_renderers[entry.team].ant_data[entry.index]
					if(ant_position.distance_to(found_ant.global_position) < search_distance):
						enemy_ants.append(entry)
				elif(entry.type == "warrior" and entry.team != team):
					var found_ant = ant_renderers[entry.team].ant_data[entry.index]
					if(ant_position.distance_to(found_ant.global_position) < search_distance):
						enemy_ants.append(entry)
				
				if(entry.has("team") and entry.team != team):
					continue 
				if(entry.type == "food_source"):
					food_sources.append(entry)

	var enemy_ant = null
	var food_source = null 
	var discovered_trail = null
	if(discovered_trails.size() > 0):
		discovered_trail = discovered_trails[Utils.get_random_index(discovered_trails)]
	if(food_sources.size() > 0):
		food_source = food_sources[Utils.get_random_index(food_sources)]
	if(enemy_ants.size() > 0):
		enemy_ant = enemy_ants[Utils.get_random_index(enemy_ants)]
	
	return {"food_source": food_source, "discovered_trail": discovered_trail, "enemy_ant": enemy_ant}

func _physics_process(delta):
	for i in ant_data.size():
		var ant = ant_data[i]
		var trail_index = ant.trail_index

		if(ant.dead):
			world_grid.unregister_entity({"type": "ant", "team": team, "index": i}, ant.cell)
			continue
		
		#if(ant.fleeing != null and !ant.fleeingBool):
			#ant.fleeingBool = true
			#var enemyAnt = base.getAnt(ant.fleeing[0], ant.fleeing[1], "warrior")
			#ant.following_trail = false
			#ant.backtracking = false 
			#ant.targeting_food = false 
			#ant.trail_index = -1	
			#var forward = (ant.global_position - enemyAnt.global_position).normalized()
			#var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
			#var angle_rad = deg_to_rad(angle_deg)
			#
			#var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
			#var new_target = (ant.position + rotated_forward) * wander_distance
			#ant.path.append(new_target)
					#
			#print("Ant fleeing from: ", enemyAnt)

			#world_grid.unregister_entity(to_global(ant.position), {"type": "ant", "team": team, "index": i}, ant.cell)
			#continue
		
		if(ant.path.size() == 0):
			# Ant is at base
			#print("ant at base: ", i)
			#if(ant.reporting_enemy):
				#warrior_ant_renderer.spawn_ant()
				
			if(ant.reporting_enemy):
				if(current_warriors < max_warriors):
					warrior_ant_renderer.spawn_ant()
					current_warriors += 1
				
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
				world_grid.unregister_entity(ant.food_source.cell, {"type": "food_source", "position": pos, "food_left": ant.food_source.food_left})
				
						
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
				
			if(!ant.backtracking): # and !ant.fleeingBool
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
			else:#elif(!ant.fleeingBool): 
				# Backtrack
				ant.path.pop_back() 
			#elif(ant.fleeingBool):
				#print('process next flee target')
				#var enemyAnt = base.getAnt(ant.fleeing[0], ant.fleeing[1], "warrior")	
				#var forward = (ant.global_position - enemyAnt.global_position).normalized()
				#var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
				#var angle_rad = deg_to_rad(angle_deg)
				#
				#var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
				#var new_target = (ant.position + rotated_forward) * wander_distance
				#ant.path.append(new_target)
		
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
		var current_movement_cell = world_grid.position_to_movement_cell(to_global(new_pos))
		
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
				if(current_warriors < max_warriors):
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
		
		var new_global = to_global(new_pos)
		
		if(current_movement_cell != ant.movement_cell):
			ant.movement_cell = current_movement_cell
		
		if(currentCell != ant.cell):
			world_grid.unregister_entity( 
			{"type": "ant", "team": team, "index": i, "global_position": ant.previous_global}, 
			ant.cell)
			
			ant.cell = world_grid.position_to_cell(new_global)
			world_grid.register_entity(ant.cell, 
			{"type": "ant", "team": team, "index": i, "global_position": new_global})
			ant.previous_global = new_global

		ant.velocity = ant.position - new_pos
		ant.position = new_pos
		ant.global_position = new_global


		var transform = Transform3D(smoothed_basis, new_pos)

		multimesh.set_instance_transform(i, transform)

func spawn_ant(): 
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
	
	
