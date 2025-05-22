extends MultiMeshInstance3D

var instance_count
@export var mesh_to_use: Mesh
@export var search_depth: int = 1 
@export var wander_distance := .5
@export var wander_angle_deg := 60.0

@onready var ant_renderer = $"../AntRenderer"
@onready var carried_food_renderer = $"../CarriedFoodRenderer"

var team 
var trails
var antSpeed
var world_grid

var base
var paths = [] 
var antData = [] 
var deadAnts = []
var antsAlive = 0 

var colors = [
	Color(0.0, 0.0, 3.5),
	Color(0.0, 0.0, 0.0),
	Color(0.0, 3.5, 3.5),
	Color(0.0, 3.5, 3.5),
]

func init(): 
	instance_count = 1 + int(Global.max_ants / 50)
	antSpeed = Global.warrior_speed
	trails = ant_renderer.trails
	
	# Create and configure the MultiMesh
	var material = StandardMaterial3D.new() 
	material.albedo_color = colors[team]
	
	var multimesh = MultiMesh.new()
	multimesh.mesh = mesh_to_use
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = instance_count
	material_override = material
	self.multimesh = multimesh

func reset(): 
	antData = [] 
	deadAnts = [] 
	antsAlive = 0 
	self.multimesh = null
	
func _ready():
	await get_tree().process_frame
	base = get_parent() 
	world_grid = get_parent().world_grid
	team = get_parent().team
	init()

func removeTrail(index): 
	trails[index] = null 

func add_path_to_grid(path, antIndex): 
	var trail = []
	var cells = []
	
	var trailIndex = trails.size()
	for i in range(trails.size()):
		if trails[i] == null:
			trailIndex = i
			break
	
	for node in path: 
		# Add trail index here too
		trail.append(to_global(node))
		var cell = world_grid.position_to_cell(to_global(node))
		cells.append(cell)
		world_grid.register_entity(to_global(node), {
			"type": "enemyTrail", 
			"trailIndex": trailIndex, 
			"nodeIndex": trail.size() - 1,
			"team": team
		}, cell)
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
	return trailIndex

func remove_trail_from_grid(index): 
	for i in range(trails[index].path.size()):
		var node = trails[index].path[i]
		var cell = trails[index].cells[i]
		world_grid.unregister_entity(node, {
			"type": "foodTrail", 
			"trailIndex": index, 
			"nodeIndex": i,
			"team": team
		}, cell)

func get_random_index(arr: Array):
	if arr.is_empty():
		return -1
	return randi_range(0, arr.size() - 1)

func scan_nearby_cells(center_cell):
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
				if entry.type == "warrior" and entry.team != team:
					var foundAnt = base.getAnt(entry.team, entry.index, "warrior")
					if(foundAnt.fleeing == null):
						workers.append(entry)
						discoveredEnemyWorker = entry
						break
				if entry.type == "ant" and entry.team != team:
					var foundAnt = base.getAnt(entry.team, entry.index, "worker")
					if(foundAnt.fleeing == null):
						discoveredEnemyWorker = entry
				if(entry.has("team") and entry.team != team):
					continue
				if entry.type == "foodsource" and entry.has("position"):
					foodPositions.append(entry)
				elif entry.type == "foodTrail":
					discoveredTrails.append({"trailIndex": entry.trailIndex, "nodeIndex": entry.nodeIndex, "source": entry.source})
	var discoveredTrail
	if(discoveredTrails.size() > 0):
		var index = get_random_index(discoveredTrails)
		discoveredTrail = discoveredTrails[index]
	return {"discoveredEnemyWorker": discoveredEnemyWorker, "discoveredTrail": discoveredTrail, "foundObstacles": foundObstacles}

func _physics_process(delta):
	for i in antData.size():
		var ant = antData[i]
		var trailIndex = ant.trailIndex
		
		if(ant.dead and !ant.handled_Death):
			world_grid.unregister_entity(to_global(ant.position), {"type": "warrior", "team": team, "index": i}, ant.cell)
			ant.handled_Death = true
			antsAlive -= 1
			base.decreaseWarriorCount() 
			deadAnts.append(i)
		
		if(ant.dead):
			continue
		
		if(ant.targetingAnt != null):
			if(ant.global_position.distance_to(ant.targetingAnt.global_position) < 0.1):
				# Caught ant
				ant.targetingAnt.dead = true
				ant.targetingAnt = null
				ant.backtracking = true
		
		if(ant.path.size() == 0):
			# Ant is at base
			ant.backtracking = false 
			ant.followingTrail = false
			ant.trailIndex = -1
			trailIndex = -1
			var offset_x = randf_range(-0.1, 0.1)
			var offset_z = randf_range(-0.1, 0.1)
			ant.path.append(Vector3(offset_x, 0, offset_z))
		
		if(ant.targetingAnt == null and (ant.global_position.x < -19 or ant.global_position.x > 19 or ant.global_position.z < -19 or ant.global_position.z > 19)):
			antData[i].backtracking = true 
		
		var path = ant.path 
		var pathLength = ant.path.size() 
		var trailLength = 0 
		if(trailIndex >= 0): 
			if(trails[trailIndex] == null):
				trailIndex = -1
				ant.trailIndex = -1
				ant.followingTrail = false
			else:
				trailLength = trails[trailIndex].path.size()
		
		if(ant.fleeing != null and !ant.fleeingBool):
			ant.fleeingBool = true
			var enemyAnt = base.getAnt(ant.fleeing[0], ant.fleeing[1], "warrior")
			ant.backtracking = false 
			ant.followingTrail = false
			ant.trailIndex = -1
			ant.targetingAnt = enemyAnt
			ant.path.append(to_local(enemyAnt.global_position))
		
		var currentPos:Vector3 = ant.position
		var targetPos:Vector3 = path[path.size() - 1]
		if(trailIndex >= 0 and ant.source != null and ant.source.foodLeft <= 0):
			# Food saturated 
			ant.trailIndex = -1
			ant.followingTrail = false 
			ant.backtracking = true
			ant.source = null
		
		if(currentPos.distance_to(targetPos) < 0.1):
			# Ant reaches target
			if(ant.targetingAnt != null):
				if(ant.global_position.distance_to(ant.targetingAnt.global_position) < 0.1):
					ant.targetingAnt.dead = true
					ant.targetingAnt = null
					ant.backtracking = true
				else: 
					ant.path.append(to_local(ant.targetingAnt.global_position))
			if(!ant.backtracking):
				if(ant.followingTrail):
					if(ant.path[pathLength - 1] == to_local(trails[trailIndex].path[trailLength - 1])):
						# Ant reaches food from trail
						ant.backtracking = true
					else:
						# Add next path node in trail
						ant.path.append(to_local(trails[trailIndex].path[pathLength]))
					if(ant.source.foodLeft == 0):
						# Food saturated 
						remove_trail_from_grid(trailIndex)
						var pos = Vector3(ant.source.position.x, 0, ant.source.position.z)
						world_grid.unregister_entity(global_position, {"type": "foodsource", "position": pos, "foodLeft": ant.source.foodLeft}, ant.source.cell)
				elif(ant.targetingAnt == null): 
					# Wander to new target
					var forward = (targetPos - currentPos).normalized()
					var angle_deg = randf_range(-wander_angle_deg / 2.0, wander_angle_deg / 2.0)
					var angle_rad = deg_to_rad(angle_deg)
					var rotated_forward = forward.rotated(Vector3.UP, angle_rad).normalized()
					var new_target = currentPos + rotated_forward * wander_distance
					var new_target_half = currentPos + rotated_forward * (wander_distance / 2)
					if(ant.obstacles.size() > 0): 
						for obstacle in ant.obstacles: 
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
					ant.path.append(new_target)
			else: 
				# Backtrack
				ant.path.pop_back() 
		
		var to_target = targetPos - currentPos
		var distance_to_target = to_target.length()
		# Clamp movement to remaining distance
		var max_move_distance = antSpeed * delta
		var move_distance = min(distance_to_target, max_move_distance)
		var direction = to_target.normalized()
		
		var move_vector = direction * move_distance
		var new_pos = currentPos + move_vector
		
		var current_transform = multimesh.get_instance_transform(i)
		var target_basis = Basis().looking_at(direction, Vector3.UP)
		var current_basis = current_transform.basis
		var smoothed_basis = current_basis.slerp(target_basis, 0.2)  # 0.2 = smoothing factor
		
		var currentCell = world_grid.position_to_cell(to_global(new_pos))
		if(currentCell != ant.cell):
			# Ant moves to new cell in grid 
			var search = scan_nearby_cells(currentCell)
			
			var trail
			var nodeIndex
			var trailSource
			var discoveredTrail = search.discoveredTrail
			var discoveredEnemyWorker = search.discoveredEnemyWorker
			ant.obstacles = [] 
			ant.obstacles = search.foundObstacles
			var enemyAnt
			if(discoveredEnemyWorker != null and ant.path.size() > 0 and ant.targetingAnt == null):
				var type
				if(discoveredEnemyWorker.type == "ant"):
					type = "worker"
				else:
					type = "warrior"
				enemyAnt = base.getAnt(discoveredEnemyWorker.team, discoveredEnemyWorker.index, type)
				
				ant.backtracking = false
				enemyAnt.fleeing = [team, i]
				ant.followingTrail = false 
				ant.trailIndex = -1
				ant.targetingAnt = enemyAnt
				ant.path.append(to_local(enemyAnt.global_position))
				
			if(discoveredTrail):
				trail = discoveredTrail.trailIndex
				nodeIndex = discoveredTrail.nodeIndex
				trailSource = discoveredTrail.source
				
			if(trail != null and !ant.followingTrail and ant.targetingAnt == null):
				# Existing food trail found
				ant.trailIndex = trail
				ant.followingTrail = true
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
			world_grid.unregister_entity(to_global(ant.position), {"type": "warrior", "team": team, "index": i}, ant.cell)
			ant.cell = world_grid.position_to_cell(to_global(new_pos))
			world_grid.register_entity(to_global(new_pos), {"type": "warrior", "team": team, "index": i}, ant.cell)
		ant.position = new_pos
		ant.global_position = to_global(ant.position)
		
		var transform = Transform3D(smoothed_basis, new_pos)
		multimesh.set_instance_transform(i, transform)

func spawn_ant(): 
	if(antsAlive >= instance_count):
		return 
	
	base.increaseWarriorCount()
	
	var pos = position
	var transform = Transform3D(Basis(), pos)

	var index 
	var offset_x = randf_range(-0.1, 0.1)
	var offset_z = randf_range(-0.1, 0.1)	

	var data = {
			"position": pos, 
			"global_position": to_global(pos),	
			"cell": Vector2i(0, 0),
			"path": [pos + Vector3(offset_x, 0, offset_z)],
			"obstacles": [],
			"fleeing": null, 
			"fleeingBool": false, 
			"dead": false, 
			"handled_Death": false,
			
			"backtracking": false,
			"targetingAnt": null,
			
			"trail": [],
			"trailIndex": -1,
			"followingTrail": false
		}
	
	if(antsAlive + deadAnts.size() < instance_count):
		# Append new
		index = antData.size()
		antData.append(data)
	else: 
		# Reuse dead ant index
		index = deadAnts[0]
		deadAnts.pop_front()
		antData[index] = data
	antsAlive += 1 
	multimesh.set_instance_transform(index, transform)
