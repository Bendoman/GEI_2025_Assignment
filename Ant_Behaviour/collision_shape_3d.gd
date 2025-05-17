extends CollisionShape3D
@onready var ant_base = $"../../AntBase"
var renderer

func _ready(): 
	await get_tree().process_frame
	renderer = ant_base.ant_renderer

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000.0

		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

		if result and result.has("position"):
			var position = result["position"]
			renderer.spawn_ant_at(position)
