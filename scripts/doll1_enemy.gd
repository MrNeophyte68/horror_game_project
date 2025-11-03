extends CharacterBody3D

enum DollState1 {FIRST_TIME}
var current_state

func ready():
	current_state = DollState1.FIRST_TIME

func _physics_process(delta: float) -> void:
	if current_state == DollState1.FIRST_TIME:
		pass
	move_and_slide()
	
	
