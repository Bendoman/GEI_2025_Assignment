extends MultiMeshInstance3D

var instance_count
var starting_count

@export var mesh_to_use: Mesh
@export var material_to_use: Material
@onready var food_trail_renderer = $"../FoodTrailRenderer"

var antSpeed: float = Global.ant_speed

@export var wander_distance := .5
@export var wander_angle_deg := 60.0
@onready var dead_warrior_renderer = $"../DeadWarriorRenderer"

@export var search_depth: int = 1 
@export var consumptionRate: int = 1
@onready var warrior_ant_renderer = $"../WarriorAntRenderer"

@export var backtracking := false 
@onready var carried_food_renderer = $"../CarriedFoodRenderer"

var maxWarriors = 1
var currentWarriors = 0

var team 
var world_grid

var paths = [] 
var antData = [] 
var base

var antsAlive = 0 

var colors = [
	Color(0.0, 0.0, 0.5),  # Navy
	Color(0.0, 0.0, 0.0),  # Black
	Color(0.0, 0.0, 0.0),  # Black
	Color(0.0, 0.0, 0.0),  # Black
]

func populate_ant_data(): 
	for i in instance_count:
		if i >= starting_count:
			continue
			
		var offset_x = randf_range(-0.1, 0.1)
		var offset_z = randf_range(-0.1, 0.1)		
		base.increaseAntCount()

		var pos = position
		var transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(i, transform)
		
		antsAlive += 1
		antData.append({
			"index": antData.size() - 1,
			
			"position": pos, 
			"cell": Vector2i(0, 0),
			"global_position": to_global(pos),
			"path": [pos + Vector3(offset_x, 0, offset_z)],
			
			"obstacles": [],
			
			"dead": false,
			"fleeing": null,
			"fleeingBool": false,
			"handled_Death": false,
			
			"carryingFood": false, 
			"backtracking": false,
			"targetingFood": false,
			"reportingEnemy": false, 
			
			"trail": [],
			"source": null,
			"trailIndex": -1,
			"followingTrail": false,
		})

func init(): 	
	print("init from team: ", team)
	instance_count = Global.max_ants
	starting_count = Global.starting_ants
	
	maxWarriors = int(1 + starting_count / 50)
	# Create mesh material
	var material = StandardMaterial3D.new() 
	material.albedo_color = colors[team]
	
	# Create and configure the MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	material_override = material
	self.multimesh = multimesh
	
	if(!Global.stopped):
		populate_ant_data()

func reset(): 
	antData = [] 
	maxWarriors = 1
	currentWarriors = 0 
	antsAlive = 0
	self.multimesh = null
	
func _ready():
	await get_tree().process_frame
	base = get_parent() 
	world_grid = get_parent().world_grid
	team = get_parent().team
	#print_debug(team)
	
	
	init()


func get_random_index(arr: Array):
	if arr.is_empty():
		return -1
	return randi_range(0, arr.size() - 1)

func find_nearest_food(center_cell):
	var foodPositions = []
	var discoveredTrails = [] 
	var workers = [] 
	var discoveredEnemyWorker = null 
	var foundObstacles = [] 
	
	for x in range(center_cell.x - search_depth, center_cell.x + search_depth + 1):
		for z in range(center_cell.y - search_depth, center_cell.y + search_depth + 1):
			var cell = Vector2i(x, z)
			if(!world_grid.grid.has(cell)):
				continue
			var entries = world_grid.get_entities_at_cell(cell)
			for entry in entries:
				if(entry.type == "obstacle"):
					foundObstacles.append(entry)
					
				if entry.type == "ant" and entry.team != team:
					discoveredEnemyWorker = entry
				
				if(entry.has("team") and entry.team != team):
					continue
					
				if entry.type == "foodsource" and entry.has("position"):
					foodPositions.append(entry)
				elif entry.type == "foodTrail":
					discoveredTrails.append({"trailIndex": entry.trailIndex, "nodeIndex": entry.nodeIndex, "source": entry.source})
				#elif entry.type == "obstacle":
					
	var foodPos = null
	var discoveredTrail = null
	#var discoveredEnemyWorker = null 
	if(discoveredTrails.size() > 0):
		var index = get_random_index(discoveredTrails)
		discoveredTrail = discoveredTrails[index]
	if(foodPositions.size() > 0):
		foodPos = foodPositions[get_random_index(foodPositions)]
	#if(workers.size() > 0):
		#var index = get_random_index(workers)
		#discoveredEnemyWorker = workers[index]
		
	return {"foodPos": foodPos, "discoveredTrail": discoveredTrail, "discoveredEnemyWorker": discoveredEnemyWorker, "foundObstacles": foundObstacles}
	#return {"foodPos": foodPos, "trailIndex": trailIndex, "nodeIndex": nodeIndex, "trailSource": trailSource}

var trails = []
func removeTrail(index): 
	trails[index] = null 
	
func add_path_to_grid(path, source): 
	var trail = []
	var cells = []
	
	var trailIndex = trails.size()
	for i in range(trails.size()):
		if trails[i] == null:
			trailIndex = i
			break
	
	for node in path: 
		#food_trail_renderer.addTrailNode(to_global(node))
		# Add trail index here too
		trail.append(to_global(node))
		var cell = world_grid.position_to_cell(to_global(node))
		cells.append(cell)
		world_grid.register_entity(to_global(node), {
			"type": "foodTrail", 
			"trailIndex": trailIndex, 
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
	if(trailIndex == trails.size()):
		trails.append(value)
	else: 
		trails[trailIndex] = value
	#print(trails)
	#print_debug(world_grid.grid)
	return trailIndex

func remove_trail_from_grid(index): 
	#print("removing trail: ", trails[index])
	for i in range(trails[index].path.size()):
		var node = trails[index].path[i]
		#print_debug("node index: ", i)
		var cell = trails[index].cells[i]
		#print(cell)
		world_grid.unregister_entity(node, {
			"type": "foodTrail", 
			"trailIndex": index, 
			"nodeIndex": i,
			"team": team
		}, cell)
	#print_debug("Removing trail ", world_grid.grid)





# "position": pos, 
# "cell": Vector2i(0, 0),
# "path": [pos + Vector3(offset_x, 0, offset_z)],

# "carryingFood": true, 
# "backtracking": false,
# "targetingFood": false,

# "trail": [],
# "trailIndex": 0,
# "followingTrail": false,
var deadAnts = [] 
func _physics_process(delta):
	if(Global.stopped): 
		return 

	for i in antData.size():
		var ant = antData[i]
		var trailIndex = ant.trailIndex
		
		if(ant.dead and !ant.handled_Death):
			world_grid.unregister_entity(to_global(ant.position), {"type": "ant", "team": team, "index": i}, ant.cell)
			dead_warrior_renderer.addDeadAnt(i)
			ant.handled_Death = true
			base.decreaseAntCount()
			antsAlive -= 1
			deadAnts.append(i)
		
		if(ant.dead):
			continue
			
		var trailLength = 0 
		if(trailIndex >= 0): 
			if(trails[trailIndex] == null):
				trailIndex = -1
				ant.trailIndex = -1
				ant.followingTrail = false
				ant.source = null
			else:
				trailLength = trails[trailIndex].path.size()
		
		if(ant.fleeing != null and !ant.fleeingBool):
			ant.fleeingBool = true
			var enemyAnt = base.getAnt(ant.fleeing[0], ant.fleeing[1], "warrior")
			ant.followingTrail = false
			ant.backtracking = false 
			ant.targetingFood = false 
			ant.trailIndex = -1	
			var forward = (ant.global_position - enemyAnt.global_position).normalized()
			var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
			var angle_rad = deg_to_rad(angle_deg)
			
			var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
			var new_target = (ant.position + rotated_forward) * wander_distance
			ant.path.append(new_target)
			
			#print("Ant fleeing from: ", enemyAnt)

			#world_grid.unregister_entity(to_global(ant.position), {"type": "ant", "team": team, "index": i}, ant.cell)
			#continue
		if(trailIndex >= 0 and ant.source != null and ant.source.foodLeft <= 0):
			# Food saturated 
			if(trails[trailIndex] != null):
			#if(ant.source.foodLeft <= 0):
				# Food saturated 
				remove_trail_from_grid(ant.trailIndex)
				var pos = Vector3(ant.source.position.x, 0, ant.source.position.z)
				world_grid.unregister_entity(global_position, {"type": "foodsource", "position": pos, "foodLeft": ant.source.foodLeft}, ant.source.cell)
				removeTrail(ant.trailIndex)
				
						
			#trails[trailIndex].assignedAnts -= 1
			#if(trails[trailIndex].assignedAnts <= 0):
				#removeTrail(trailIndex)
			#removeTrail(ant.trailIndex)
			
				#print("Trails: ", trails)
				
			ant.trailIndex = -1
			ant.followingTrail = false 
			#ant.backtracking = true
			ant.source = null
			
		if(ant.path.size() == 0):
			# Ant is at base
			#print("ant at base: ", i)
			#if(ant.reportingEnemy):
				#warrior_ant_renderer.spawn_ant()
				
			if(ant.reportingEnemy):
				if(currentWarriors < maxWarriors):
					base.addToWarriorQueue()
					#base.warriorQueue += 1
					currentWarriors += 1
					#warrior_ant_renderer.spawn_ant()
				
			if(ant.carryingFood):
				base.incrementFoodLevel(consumptionRate)
				#print("Food returned to base: ", base.foodLevel)
			ant.carryingFood = false
			ant.reportingEnemy = false
			carried_food_renderer.removeCarriedFood(i)
			
			ant.backtracking = false 
			if(ant.followingTrail and trailIndex != -1):
				ant.path.append(to_local(trails[trailIndex].path[0]))
			else:
				var offset_x = randf_range(-0.1, 0.1)
				var offset_z = randf_range(-0.1, 0.1)
				ant.path.append(Vector3(offset_x, 0, offset_z))
		#elif(antData[i].path.size() >= 5 and !ant.followingTrail):
			#antData[i].backtracking = true 
		elif(!ant.followingTrail):
			if(ant.path.size() > 25 or ant.global_position.x < -19 or ant.global_position.x > 19 or ant.global_position.z < -19 or ant.global_position.z > 19):
				antData[i].backtracking = true 
		
		
		var path = ant.path 
		var pathLength = ant.path.size() 
		


		var currentPos:Vector3 = ant.position
		var targetPos:Vector3 = path[path.size() - 1]
		


		if(currentPos.distance_to(targetPos) < 0.1):
			#if(ant.has("source") and ant.source != null):
				#print(ant.source.foodLeft)
			# Ant reaches target
			 #or ant.path[pathLength - 1] == trails[trailIndex][trailLength - 1]
			if(ant.targetingFood and ant.source != null): 
				ant.backtracking = true
				ant.targetingFood = false 
				
				# Ant reaches newly found food
				if(ant.source.foodLeft > 0):
					ant.carryingFood = true
					carried_food_renderer.addCarriedFood(i)
					ant.trailIndex = add_path_to_grid(ant.path, ant.source)
					ant.followingTrail = true
					trails[ant.trailIndex].assignedAnts += 1
					ant.source.foodLeft -= consumptionRate
				
			if(!ant.backtracking and !ant.fleeingBool):
				if(ant.followingTrail):
					if(ant.path[pathLength - 1] == to_local(trails[trailIndex].path[trailLength - 1]) and ant.source.foodLeft > 0):
						#print(ant.path)
						# Ant reaches food from trail
						ant.backtracking = true
						ant.carryingFood = true
						carried_food_renderer.addCarriedFood(i)
						ant.source.foodLeft -= consumptionRate
						#print_debug(ant.source.foodLeft)
					else:
						# Add next path node in trail
						ant.path.append(to_local(trails[trailIndex].path[pathLength]))
				else: 
					# Wander to new target
					#var forward = (targetPos - currentPos).normalized() 
					#var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
					#var angle_rad = deg_to_rad(angle_deg)
					#
					#var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
					#var new_target = (currentPos + rotated_forward) * wander_distance
					#var new_target_half = (currentPos + rotated_forward) * (wander_distance/2)
					
					var forward = (targetPos - currentPos).normalized()
					var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
					var angle_rad = deg_to_rad(angle_deg)

					var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
					var new_target = currentPos + rotated_forward * wander_distance
					var new_target_half = currentPos + rotated_forward * (wander_distance / 2)
					#var new_target_quarter = currentPos + rotated_forward * (wander_distance / 4)

					#print(new_target)
					#print(new_target_half)
					#print(
						#"new_target_cell ", world_grid.position_to_cell(to_global(new_target)), 
						#" half target cell ", world_grid.position_to_cell(to_global(new_target_half)))
					
					if(ant.obstacles.size() > 0): 
						for obstacle in ant.obstacles: 
							#print(ant.cell, world_grid.position_to_cell(to_global(new_target)), obstacle.cell)
							if world_grid.position_to_cell(to_global(ant.position)) != obstacle.cell and (world_grid.position_to_cell(to_global(new_target)) == obstacle.cell or world_grid.position_to_cell(to_global(new_target_half)) == obstacle.cell):
								var loops = 0 
								while world_grid.position_to_cell(to_global(new_target)) == obstacle.cell or world_grid.position_to_cell(to_global(new_target_half)) == obstacle.cell:
									if(loops > 100):
										break
									loops += 1
									forward = (targetPos - currentPos).normalized()
									angle_deg = randf_range(-wander_angle_deg * 1.2, wander_angle_deg * 1.2)
									angle_rad = deg_to_rad(angle_deg)
									rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
									new_target = currentPos + rotated_forward * wander_distance
									new_target_half = currentPos + rotated_forward * (wander_distance / 2)
								
								#print("About to walk through obstacle")
							#if world_grid.position_to_cell(to_global(new_target_half)) == obstacle.cell:
								#print("About to walk through obstacle")
					
					ant.path.append(new_target)
					
					
					
					
			elif(!ant.fleeingBool): 
				# Backtrack
				ant.path.pop_back() 
			elif(ant.fleeingBool):
				#print('process next flee target')
				var enemyAnt = base.getAnt(ant.fleeing[0], ant.fleeing[1], "warrior")	
				if(enemyAnt.dead):
					print("Oops fleeing ant is dead")
					ant.fleeing = null
					ant.fleeingBool = false
					ant.backtracking = true 
				else:
					var forward = (ant.global_position - enemyAnt.global_position).normalized()
					var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
					var angle_rad = deg_to_rad(angle_deg)
					
					var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
					var new_target = (ant.position + rotated_forward) * wander_distance
					var new_target_half = currentPos + rotated_forward * (wander_distance / 2)	
					ant.path.append(new_target)
					
					if(ant.obstacles.size() > 0): 
						for obstacle in ant.obstacles: 
							#print(ant.cell, world_grid.position_to_cell(to_global(new_target)), obstacle.cell)
							if world_grid.position_to_cell(to_global(ant.position)) != obstacle.cell and (world_grid.position_to_cell(to_global(new_target)) == obstacle.cell or world_grid.position_to_cell(to_global(new_target_half)) == obstacle.cell):
								var loops = 0 
								while world_grid.position_to_cell(to_global(new_target)) == obstacle.cell or world_grid.position_to_cell(to_global(new_target_half)) == obstacle.cell:
									if(loops > 100):
										break
									loops += 1
									forward = (targetPos - currentPos).normalized()
									angle_deg = randf_range(-wander_angle_deg * 1.2, wander_angle_deg * 1.2)
									angle_rad = deg_to_rad(angle_deg)
									rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
									new_target = currentPos + rotated_forward * wander_distance
									new_target_half = currentPos + rotated_forward * (wander_distance / 2)
		
		#var offset_x = randf_range(-0.075, 0.075)
		#var offset_z = randf_range(-0.05, 0.05)
		#var offset = Vector3(offset_x, 0, offset_z)
		#var direction = ((targetPos + offset) - currentPos).normalized()
		
		var to_target = targetPos - currentPos
		var distance_to_target = to_target.length()

		# Clamp movement to remaining distance
		var max_move_distance = antSpeed * delta
		var move_distance = min(distance_to_target, max_move_distance)
		var direction = to_target.normalized()
		var move_vector = direction * move_distance

		#var direction = (targetPos - currentPos).normalized()
		#var move_vector = direction * antSpeed * delta
		var new_pos = currentPos + move_vector
		#if(ant.obstacles.size() > 0): 
			#for obstacle in ant.obstacles: 
				#if world_grid.position_to_cell(to_global(new_pos)) == obstacle.cell:
					#print("Alert, IN OBSTACLE")
		#var direction = (targetPos - currentPos).normalized()
		#var move_vector = direction * antSpeed * delta
		#var new_pos = currentPos + move_vector
		
		var current_transform = multimesh.get_instance_transform(i)
		var target_basis = Basis().looking_at(direction, Vector3.UP)
		var current_basis = current_transform.basis
		var smoothed_basis = current_basis.slerp(target_basis, 0.2)  # 0.2 = smoothing factor

		var currentCell = world_grid.position_to_cell(to_global(new_pos))
		if(currentCell != ant.cell and !ant.reportingEnemy):
			# Ant moves to new cell in grid 
			ant.obstacles = [] 
			var search = find_nearest_food(currentCell)
			var trail
			var nodeIndex
			var trailSource
			var discoveredTrail = search.discoveredTrail
			var discoveredEnemyWorker = search.discoveredEnemyWorker
			var enemyAnt
			ant.obstacles = search.foundObstacles
			if ant.fleeing == null:
				if(discoveredEnemyWorker != null):
					#print(base.getAnt(discoveredEnemyWorker.team, discoveredEnemyWorker.index, "worker"))
					enemyAnt = base.getAnt(discoveredEnemyWorker.team, discoveredEnemyWorker.index, "worker")
					
				if(discoveredTrail != null and !ant.carryingFood and !ant.reportingEnemy):
					trail = discoveredTrail.trailIndex
					nodeIndex = discoveredTrail.nodeIndex
					trailSource = discoveredTrail.source

				var foodPos
				var source = search.foodPos
				if(source != null):
					foodPos = search.foodPos.position
					ant.source = source
					
				if(enemyAnt != null and ant.path.size() > 1): 
					# Found enemey ant
					#ant.path.append(to_local(enemyAnt.global_position))
					#print("Path to enemey found: ", ant, ant.backtracking, ant.reportingEnemy)
					if(currentWarriors < maxWarriors):
						if(ant.path.size() > 1):
							ant.path.pop_back()
						ant.backtracking = true
						ant.reportingEnemy = true
						ant.targetingFood = false
					
				if(trail != null and !ant.followingTrail and !ant.reportingEnemy):
					# Existing food trail found
					ant.trailIndex = trail
					ant.followingTrail = true
					ant.targetingFood = false
					if(trails[ant.trailIndex] != null):
						trails[ant.trailIndex].assignedAnts += 1
						ant.path = [] 
						ant.source = trailSource
						var index = 0 
						while true: 
							ant.path.append(to_local(trails[ant.trailIndex].path[index]))
							index += 1
							if index > nodeIndex:
								break
						ant.path.resize(nodeIndex + 1)	
						ant.backtracking = false
						#print_debug("reseting backtracking here")
				elif(foodPos != null and !ant.followingTrail and !ant.reportingEnemy): 
					#print_debug("in here")
					# Target found food
					var local = to_local(foodPos)
					ant.path.pop_back()
					ant.path.append(Vector3(local.x, ant.position.y, local.z))
					ant.targetingFood = true
					ant.source = source
				
		if(currentCell != ant.cell):
			world_grid.unregister_entity(to_global(ant.position), {"type": "ant", "team": team, "index": i}, ant.cell)
			ant.cell = world_grid.position_to_cell(to_global(new_pos))
			world_grid.register_entity(to_global(new_pos), {"type": "ant", "team": team, "index": i}, ant.cell)

		
		ant.position = new_pos
		ant.global_position = to_global(ant.position)

		var transform = Transform3D(smoothed_basis, new_pos)
		multimesh.set_instance_transform(i, transform)

func spawn_ant(): 
	print("before", antsAlive)
	
	if(antsAlive >= instance_count):
		return 
		
	print("after")
	base.increaseAntCount()
	#var pos = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * randf() * spawn_radius
	var index
	
	var pos = position
	var transform = Transform3D(Basis(), pos)
	
	var offset_x = randf_range(-0.1, 0.1)
	var offset_z = randf_range(-0.1, 0.1)
	
	var data = {
		"index": antData.size() - 1,
		
		"position": pos, 
		"cell": Vector2i(0, 0),
		"global_position": to_global(pos),
		"path": [pos + Vector3(offset_x, 0, offset_z)],
		
		"obstacles": [],
		
		"dead": false,
		"fleeing": null,
		"fleeingBool": false,
		"handled_Death": false,
		
		"carryingFood": false, 
		"backtracking": false,
		"targetingFood": false,
		"reportingEnemy": false, 
		
		"trail": [],
		"source": null,
		"trailIndex": -1,
		"followingTrail": false,
	}

		
	if(antsAlive + deadAnts.size() < instance_count):
		index = antData.size()
		antData.append(data)
	else:
		index = deadAnts[0]
		deadAnts.pop_front()
		antData[index] = data

	multimesh.set_instance_transform(index, transform)


	antsAlive += 1
