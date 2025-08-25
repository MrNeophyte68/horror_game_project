extends Node3D

var has_played_elevator_open := false
var has_played_elevator_close := false

@onready var gate_collision := $gate_collision
@onready var animation_player := $AnimationPlayer

func _ready() -> void:
	$fade_out/fade/ColorRect.color = Color(0, 0, 0, 0)

func elevator_open():
	if has_played_elevator_open:
		return

	$MeshInstance3D/StaticBody3D/gate_collision.disabled = true
	animation_player.play_backwards("elevator_open")

	has_played_elevator_open = true
	has_played_elevator_close = false  # Allow closing again if needed

func elevator_close():
	if has_played_elevator_close:
		return

	$MeshInstance3D/StaticBody3D/gate_collision.disabled = false
	has_played_elevator_close = true
	has_played_elevator_open = false  # Allow opening again if needed
	animation_player.play("elevator_open")
	await get_tree().create_timer(3.5, false).timeout
	$Path3D/AnimationPlayer.play("elevator_moving")
	await get_tree().create_timer(10.0, false).timeout
	elevator_open()
