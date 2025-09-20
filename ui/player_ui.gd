extends Control

#variables for stamina bar
@onready var stamina = $TextureProgressBar
var can_regen = false
var time_to_wait = 6.0
var s_timer = 0
var can_start_stimer = true
var can_crouch = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$pause_menu.visible = false
	stamina.value = stamina.max_value

func resume_game():
	get_tree().paused = false
	$pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func quit_game():
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		$pause_menu.visible = !$pause_menu.visible
		get_tree().paused = $pause_menu.visible
		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if !get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if can_regen == false && stamina.value != 300 or stamina.value == 0:
		can_start_stimer = true
		if can_start_stimer:
			s_timer += delta
			if s_timer >= time_to_wait:
				can_regen = true
				can_start_stimer = false
				s_timer = 0
				
	if stamina.value == 300:
		can_regen = false
		
	if can_regen == true:
		stamina.value += 0.5
		can_start_stimer = false
		s_timer = 0
	
	if Input.is_action_just_pressed("crouch"):
		can_crouch = !can_crouch
	
	if !can_crouch and Input.is_action_pressed("sprint") and (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")):
		stamina.value -= 1.0
		can_regen = false
		s_timer = 0
