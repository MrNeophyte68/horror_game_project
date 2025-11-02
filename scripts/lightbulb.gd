extends Node3D


var light_on: bool = true


func _process(_delta: float) -> void:
	if light_on:
		$ceiling_lamp_mp_1_on.visible = true
		$ceiling_lamp_mp_1_off.visible = false
	else:
		$ceiling_lamp_mp_1_on.visible = false
		$ceiling_lamp_mp_1_off.visible = true
