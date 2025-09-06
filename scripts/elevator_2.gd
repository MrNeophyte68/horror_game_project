extends Node3D

@onready var animation_player := $AnimationPlayer
@onready var button_collision := $ElevatorCall/CollisionShape3D
@onready var door_collision := $ElevatorPlatform/DoorCollision/StaticBody3D/CollisionShape3D

var up := true
var down := false
var has_opened := false 
var has_closed := false 

func elevator_move():
	if up:
		door_collision.disabled = false
		animation_player.play("Open")
		button_collision.disabled = true
		await animation_player.animation_finished
		
		animation_player.play("Move Up")
		$ElevatorCall.visible = false
		await animation_player.animation_finished
		
		$ElevatorCall.visible = true
		animation_player.play_backwards("Open")
		door_collision.disabled = true
		button_collision.disabled = false
		up = false
		down = true
	
	else:
		door_collision.disabled = false
		animation_player.play("Open")
		button_collision.disabled = true
		await animation_player.animation_finished
		
		animation_player.play("Move Down")
		$ElevatorCall.visible = false
		await animation_player.animation_finished
		
		$ElevatorCall.visible = true
		animation_player.play_backwards("Open")
		door_collision.disabled = true
		button_collision.disabled = false
		down = false
		up = true
