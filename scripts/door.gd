extends Node3D

var opened = false

func ai_enter_door(body):
	if body.name == "Stalker" and $AnimationPlayer.current_animation != "open":
		opened = true
		$AnimationPlayer.play("open")
			
func ai_exit_door(body):
	if body.name == "Stalker" and $AnimationPlayer.current_animation != "open":
		opened = false
		$AnimationPlayer.play_backwards("open")

func toggle_door():
	if $AnimationPlayer.current_animation != "open":
		opened = !opened
		if !opened:
			$AnimationPlayer.play_backwards("open")
		if opened:
			$AnimationPlayer.play("open")
