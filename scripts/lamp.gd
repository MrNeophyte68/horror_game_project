extends Node3D

var light_on: bool = true


func _process(_delta: float) -> void:
	if light_on:
		$on.visible = true
		$off.visible = false
	else:
		$on.visible = false
		$off.visible = true
