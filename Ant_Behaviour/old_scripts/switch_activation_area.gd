extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Signal function
func _on_area3d_body_entered(body):
	if body:
		print("Body entered:", body.name)

# Optionally handle body exited
func _on_area3d_body_exited(body):
	if body:
		print("Body exited:", body.name)
