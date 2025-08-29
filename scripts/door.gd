extends Node3D

var opened = false
var front = false
var back = false
var front_opened = false
var back_opened = false
var ai_facing_front = false
var ai_facing_back = false

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

func ai_facing_door_front(body):
	if body.name == "Stalker":
		ai_facing_front = true
		ai_facing_back = false

func ai_facing_door_back(body):
	if body.name == "Stalker":
		ai_facing_front = false
		ai_facing_back = true

func toggle_door():
	if $AnimationPlayer.is_playing():
		return  # Wait for the current animation to finish

	opened = !opened

	if !opened:
		if front_opened:
			$AnimationPlayer.play_backwards("open")
			front_opened = false
		elif back_opened:
			$AnimationPlayer.play_backwards("open1")
			back_opened = false
	else:
		if front:
			$AnimationPlayer.play("open")
			front_opened = true
		elif back:
			$AnimationPlayer.play("open1")
			back_opened = true

func _process(delta):
	
	if ai_facing_front and $AnimationPlayer.current_animation != "open" and !opened:
		opened = true
		front_opened = true
		$AnimationPlayer.play("open")
	
	if ai_facing_back and $AnimationPlayer.current_animation != "open" and !opened:
		opened = true
		back_opened = true
		$AnimationPlayer.play("open1")
		
		
	
