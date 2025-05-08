extends CharacterBody3D
#class_name Ant
#
## Ant physical dimensions (pill shape): radius ~0.122m, height ~0.401m
## Steering parameters scaled for small ant
#
#@export var mass: float = 0.01            # kg
#@export var max_force: float = 0.1       # Newtons
#@export var max_speed: float = 0.2       # m/s
#@export var damping: float = 0.05
#@export var banking: float = 0.05
#
## Wander behavior parameters (scaled to ant size)
#@export var wander_distance: float = 0.3 # m
#@export var wander_radius: float = 0.15  # m
#@export var wander_jitter: float = 0.5   # m/s jitter intensity
#
## Pause control
#@export var pause: bool = false
#
## State variables
#var ant_velocity: Vector3 = Vector3.ZERO
#var acceleration: Vector3 = Vector3.ZERO
#var force: Vector3 = Vector3.ZERO
#var speed: float = 0.0
#var wander_target: Vector3 = Vector3.ZERO
#
#func _ready():
	## Initialize wander target on the XZ plane
	#wander_target = random_point_in_unit_sphere()
	#wander_target.y = 0.0
	#wander_target = wander_target.normalized() * wander_radius
#
#func _physics_process(delta: float) -> void:
	#if pause:
		#return
#
	## Calculate and apply wander steering
	#force = calculate_wander(delta)
	#acceleration = force / mass
	#ant_velocity += acceleration * delta
#
	## Limit speed and apply damping
	#ant_velocity = ant_velocity.limit_length(max_speed)
	#ant_velocity -= ant_velocity * damping * delta
	#speed = ant_velocity.length()
#
	#if speed > 0.0:
		## Apply velocity and move
		#velocity = ant_velocity
		#move_and_slide()
#
		## Banking (tilt into turns)
		#var up_dir: Vector3 = global_transform.basis.y.lerp(Vector3.UP + acceleration * banking, delta * 5.0)
		#look_at(global_transform.origin + ant_velocity, up_dir)
#
## Generate a random point inside unit sphere (uniform distribution)
#func random_point_in_unit_sphere() -> Vector3:
	#var u: float = randf()
	#var v: float = randf()
	#var theta: float = 2.0 * PI * u
	#var phi: float = acos(2.0 * v - 1.0)
	#var r: float = pow(randf(), 1.0 / 3.0)
	#return Vector3(
		#r * sin(phi) * cos(theta),
		#r * sin(phi) * sin(theta),
		#r * cos(phi)
	#)
#
#func calculate_wander(delta: float) -> Vector3:
	## Update wander target with jitter (XZ plane only)
	#var jitter: Vector3 = random_point_in_unit_sphere() * wander_jitter * delta
	#jitter.y = 0.0
	#wander_target += jitter
	#wander_target = wander_target.normalized() * wander_radius
#
	## Compute circle center in front of the ant
	#var forward_dir: Vector3 = -global_transform.basis.z.normalized()
	#var circle_center: Vector3 = global_transform.origin + forward_dir * wander_distance
#
	## Compute world target on surface
	#var target: Vector3 = circle_center + wander_target
	#target.y = global_transform.origin.y
#
	## Seek behavior: calculate steering
	#var desired_dir: Vector3 = (target - global_transform.origin).normalized()
	#var desired_vel: Vector3 = desired_dir * max_speed
	#var steer: Vector3 = (desired_vel - ant_velocity).limit_length(max_force)
	#return steer
