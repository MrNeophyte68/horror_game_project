extends Node3D

var sensitivity = 0.2

#func _ready() -> void:
#	sensitivity = 0.0
#	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#	await get_tree().create_timer(11.0, false).timeout
#	sensitivity = 0.2

#func _input(event: InputEvent) -> void:
#	if event is InputEventMouseMotion:
#		get_parent().rotate_y(deg_to_rad(-event.relative.x * sensitivity))
#		rotate_x(deg_to_rad(-event.relative.y * sensitivity))
#		rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(90))
