extends Node3D

var opened = false
var front = false
var back = false
var front_opened = false
var back_opened = false

func ai_enter_door(body): #front
	if body.name == "Stalker" and $AnimationPlayer.current_animation != "open" and !opened:
		opened = true
		front_opened = true
		$AnimationPlayer.play("open")

func ai_enter_door_back(body): #back
	if body.name == "Stalker" and $AnimationPlayer.current_animation != "open" and !opened:
		opened = true
		back_opened = true
		$AnimationPlayer.play("open1")

func facing_front_enter(body):
	if body.name == "Player":
		front = true

func facing_front_exit(body):
	if body.name == "Player":
		front = false

func facing_back_enter(body):
	if body.name == "Player":
		back = true

func facing_back_exit(body):
	if body.name == "Player":
		back = false

func toggle_door():
	if $AnimationPlayer.current_animation != "open":
		opened = !opened
		if !opened and front_opened:
			$AnimationPlayer.play_backwards("open")
			front_opened = false
		if !opened and back_opened:
			$AnimationPlayer.play_backwards("open1")
			back_opened = false
		if front and opened:
			$AnimationPlayer.play("open")
			front_opened = true
		if back and opened:
			$AnimationPlayer.play("open1")
			back_opened = true
