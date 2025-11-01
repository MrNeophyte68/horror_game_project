extends RayCast3D

#vault check
var can_vault = false #if true player is allowed to vault

#cut wood check
var can_cut: bool = false

@onready var crosshair = get_parent().get_parent().get_node("player_ui/CanvasLayer/crosshair")
var can_interact_elevator = false
@onready var crouch_check = get_parent().get_parent()

var score: int = 0
@export var hud: Node

@onready var buy_door_message = get_parent().get_parent().get_node("player_ui/CanvasLayer/buy_door_message")
@export var door: Node3D

var fuse_check := []
@onready var fusebox = get_tree().root.get_node("Level/map/Puzzle/fusebox")
var reading: bool = false
@onready var cut_progress = $CanvasLayer/CutProgress

func _physics_process(delta: float) -> void:
	if is_colliding():
		var hit = get_collider()
		
		# Group-based interaction for fingers
		if hit.is_in_group("fingers"):
			if Input.is_action_just_pressed("interact"):
				hit.queue_free()
				score += 1
				hud.update_score(score)
		
		elif hit.is_in_group("blue_fuse"):
			if Input.is_action_just_pressed("interact"):
				hit.queue_free()
				fuse_check.append("blue_fuse")
		
		elif hit.is_in_group("red_fuse"):
			if Input.is_action_just_pressed("interact"):
				hit.queue_free()
				fuse_check.append("red_fuse")
		
		elif hit.is_in_group("green_fuse"):
			if Input.is_action_just_pressed("interact"):
				hit.queue_free()
				fuse_check.append("green_fuse")
		
		elif hit.is_in_group("yellow_fuse"):
			if Input.is_action_just_pressed("interact"):
				hit.queue_free()
				fuse_check.append("yellow_fuse")
		
		# Name-based interaction for other objects
		elif Input.is_action_just_pressed("interact"):
			match hit.name:
				"door":
					hit.get_parent().get_parent().get_parent().toggle_door()
					hit.queue_free()

				"drawer":
					hit.get_parent().get_parent().get_parent().toggle_drawer()

				"ElevatorCall":
					hit.get_parent().elevator_move()

				"exit":
					hit.get_parent().elevator_close()

				"window":
					if !crouch_check.crouching:
						can_vault = true

				"buy_door":
					if score >= 5 and hit.get_parent().get_parent().get_parent().bought == false:
						score -= 5
						hud.update_score(score)
						hit.get_parent().get_parent().get_parent().bought = true
						hit.get_parent().get_parent().get_parent().animationplayer.play("open")
						
				"fusebox_door":
					hit.get_parent().get_parent().get_parent().toggle_door()
					
				"fusebox":
					hit.get_parent().get_parent().try_inspect()
				
				"fuses":
					hit.get_parent().get_parent().try_inspect_fuses()
				
				"note":
					hit.get_parent().get_parent().read()
					
		if Input.is_action_pressed("interact"):
			match hit.name:
				"locked":
					if !crouch_check.crouching:
						can_cut = true
						if $CanvasLayer/CutProgress.value == 500.0:
							hit.get_parent().unlock()
							can_cut = false
							$CanvasLayer/CutProgress.value = 0
		else:
			can_cut = false

		# Crosshair visibility for interactables
		if hit.is_in_group("yellow_fuse") or hit.is_in_group("green_fuse") or hit.is_in_group("red_fuse") or hit.is_in_group("blue_fuse") or hit.is_in_group("fingers") or hit.name in ["door", "drawer", "ElevatorCall", "exit", "fusebox_door"]:
			if !crosshair.visible:
				crosshair.visible = true
		
		elif hit.name == "note" and !reading:
			if !crosshair.visible:
				crosshair.visible = true
				
		elif hit.name in ["buy_door"] and hit.get_parent().get_parent().get_parent().bought == false:
			if !buy_door_message.visible:
				buy_door_message.visible = true
				
		elif hit.name in ["fusebox"] and !fusebox.inspecting:
			for mesh in fusebox.highlight:
				if !mesh.visible:
					mesh.visible = true
			if !crosshair.visible:
				crosshair.visible = true
				
		elif hit.name in ["fuses"] and !fusebox.inspecting_fuses:
			for mesh in fusebox.highlight_fuse:
				if !mesh.visible:
					mesh.visible = true
			if !crosshair.visible:
				crosshair.visible = true
			
		else:
			if crosshair.visible:
				crosshair.visible = false
			if buy_door_message.visible:
				buy_door_message.visible = false
			if !fusebox.inspecting:
				for mesh in fusebox.highlight:
					if mesh.visible:
						mesh.visible = false
			if !fusebox.inspecting_fuses:
				for mesh in fusebox.highlight_fuse:
					if mesh.visible:
						mesh.visible = false
	else:
		if crosshair.visible:
			crosshair.visible = false
		if buy_door_message.visible:
				buy_door_message.visible = false
		if !fusebox.inspecting:
			for mesh in fusebox.highlight:
				if mesh.visible:
					mesh.visible = false
		if !fusebox.inspecting_fuses:
			for mesh in fusebox.highlight_fuse:
				if mesh.visible:
					mesh.visible = false
