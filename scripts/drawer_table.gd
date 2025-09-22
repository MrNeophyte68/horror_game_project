extends Node3D

var open_drawer = false

func toggle_drawer():
	if $AnimationPlayer.is_playing():
		return
		
	open_drawer = !open_drawer
	
	if open_drawer:
		$AnimationPlayer.play("open_drawer")
	else:
		$AnimationPlayer.play_backwards("open_drawer")
