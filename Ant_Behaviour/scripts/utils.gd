extends Node
static func get_random_index(arr: Array):
	if arr.is_empty():
		return -1
	return randi_range(0, arr.size() - 1)

static func add_path_to_grid(path, source): 
	pass

static func remove_trail_from_grid(index): 
	pass

static func calculate_noise_wander(noise, delta, theta, transform, wander_distance):
	var target:Vector3

	var radius = 10.0
	var amplitued = 80
	var n = noise.get_noise_1d(theta)
	var angle = deg_to_rad(n * amplitued)

	var rot = transform.basis.get_euler() 
	rot.x = 0 

	target.x = sin(angle)
	target.z = cos(angle)
	target.y = 0
	rot.z = 0 

	target *= radius

	var local_target = target + (Vector3.BACK * wander_distance)
	var projected = Basis.from_euler(rot)

	return transform.origin + (projected * local_target)

static func calculate_seek_force(target, transform, speed, velocity):
	var to_target = target - transform.origin
	to_target = to_target.normalized()

	var desired = to_target * speed
	return desired - velocity
	
