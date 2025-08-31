extends Node3D

@export var vault_target: Node3D
var can_vault = false

func window_detect(body):
	if body.name == "Player":
		body.near_window = true

func window_detect_exit(body):
	if body.name == "Player":
		body.near_window = false
