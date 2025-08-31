extends RayCast3D

#vault check
var can_vault = false

@onready var crosshair = get_parent().get_parent().get_node("player_ui/CanvasLayer/crosshair")
var can_interact_elevator = false

func _physics_process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()
		if hit.name == "door":
			if !crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().get_parent().get_parent().toggle_door()
				
		elif hit.name == "camera":
			if !crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.free()
				$"../eyes/hand/camera3".visible = true
				can_interact_elevator = true
				
		elif hit.name == "elevator":
			if can_interact_elevator:
				if !crosshair.visible:
					crosshair.visible = true
				if Input.is_action_just_pressed("interact"):
					hit.get_parent().elevator_open()
					
		elif hit.name == "exit":
			if !crosshair.visible:
				crosshair.visible = true
			if Input.is_action_just_pressed("interact"):
				hit.get_parent().elevator_close()
				
		elif hit.name == "window":
			if Input.is_action_just_pressed("interact"):
				can_vault = true
				
		else:
			if crosshair.visible:
				crosshair.visible = false
	else:
		if crosshair.visible:
			crosshair.visible = false
