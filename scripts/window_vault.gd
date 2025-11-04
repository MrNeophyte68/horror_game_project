extends Node3D

@export var vault_target: Node3D
var can_vault = false
var locked: bool = true
@onready var body: StaticBody3D = $window
@onready var animation = $AnimationPlayer
@onready var window_location = $Marker3D3

func window_detect(body):
	if body.name == "Player":
		body.near_window = true

func window_detect_exit(body):
	if body.name == "Player":
		body.near_window = false

func _process(delta: float):
	if locked:
		$wooden_plank_2.visible = true
		body.name = "locked"
	else:
		$wooden_plank_2.visible = false
		body.name = "window"

func unlock():
	locked = false
