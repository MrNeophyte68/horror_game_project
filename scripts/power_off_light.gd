extends Node3D

var light_on: bool = false
@onready var animation = $AnimationPlayer

func _process(_delta: float) -> void:
	if !animation.is_playing():
		if light_on:
			$lamp_mx_1_a_1_on.visible = true
			$lamp_mx_1_a_1_off.visible = false
		else:
			$lamp_mx_1_a_1_on.visible = false
			$lamp_mx_1_a_1_off.visible = true
