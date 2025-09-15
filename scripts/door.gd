extends Node3D

var opened = false
var closed = false

func close_door(body):
	if body.name == "Player":
		if closed:
			return
		closed = true
		if closed:
			$AnimationPlayer.play("close")

func toggle_door():
	if opened:
		return  # Wait for the current animation to finish
	
	opened = true

	if opened:
		$AnimationPlayer.play("open")
