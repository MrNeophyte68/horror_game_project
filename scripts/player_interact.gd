extends RayCast3D

#vault check
var can_vault = false

@onready var crosshair = get_parent().get_parent().get_node("player_ui/CanvasLayer/crosshair")
var can_interact_elevator = false
@onready var crouch_check = get_parent().get_parent()

var score: int = 0
@export var hud: Node

@onready var buy_door_message = get_parent().get_parent().get_node("player_ui/CanvasLayer/buy_door_message")
@export var door: Node3D

func _physics_process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()
		
		# Group-based interaction for fingers
		if hit.is_in_group("fingers"):
			if Input.is_action_just_pressed("interact"):
				hit.queue_free()
				score += 1
				hud.update_score(score)
		
		# Name-based interaction for other objects
		elif Input.is_action_just_pressed("interact"):
			match hit.name:
				"door":
					hit.get_parent().get_parent().get_parent().toggle_door()
					hit.queue_free()

				"drawer":
					hit.get_parent().get_parent().get_parent().toggle_drawer()

				"camera":
					hit.queue_free()
					$"../eyes/hand/camera3".visible = true

				"ElevatorCall":
					hit.get_parent().elevator_move()

				"exit":
					hit.get_parent().elevator_close()

				"window":
					if !crouch_check.can_crouch:
						can_vault = true
				"buy_door":
					if score >= 5 and hit.get_parent().get_parent().bought == false:
						score -= 5
						hud.update_score(score)
						hit.get_parent().get_parent().bought = true
						hit.get_parent().get_parent().animationplayer.play("open")
						
				"fusebox_door":
					hit.get_parent().get_parent().get_parent().toggle_door()
					
				"fusebox":
					hit.get_parent().get_parent().try_inspect()

		# Crosshair visibility for interactables
		if hit.is_in_group("fingers") or hit.name in ["door", "drawer", "camera", "ElevatorCall", "exit", "fusebox_door", "fusebox"]:
			if !crosshair.visible:
				crosshair.visible = true
		elif hit.name in ["buy_door"] and hit.get_parent().get_parent().bought == false:
			if !buy_door_message.visible:
				buy_door_message.visible = true
		else:
			if crosshair.visible:
				crosshair.visible = false
			if buy_door_message.visible:
				buy_door_message.visible = false
	else:
		if crosshair.visible:
			crosshair.visible = false
		if buy_door_message.visible:
				buy_door_message.visible = false
