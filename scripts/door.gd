extends Node3D

var opened = false

func toggle_door():
	if $AnimationPlayer.current_animation != "open":
		opened = !opened
		if !opened:
			$AnimationPlayer.play_backwards("open")
		if opened:
			$AnimationPlayer.play("open")
