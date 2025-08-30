extends CharacterBody3D


var SPEED = 0.0
var JUMP_VELOCITY = 4.5
const WALK_SPEED = 3.0
const SPRINT_SPEED = 6.0
var can_sprint = false

@export var cam : Node3D
@export var cam_speed : float = 5
@export var cam_rotation_amount : float = 1
var mouse_input : Vector2
var hand_pos : Vector3
@export var hand : Node3D
@export var hand_sway_amount : float = 5
@export var hand_rotation_amount : float = 1

var lerp_speed = 10.0
var direction = Vector3.ZERO
const head_bob_sprint_speed = 22.0
const head_bob_walk_speed = 14.0
const head_bob_sprint_intensity = 0.2
const head_bob_walk_intensity = 0.1
var head_bob_vector = Vector2.ZERO
var head_bob_index = 0.0
var head_bob_current_intensity = 0.0
@onready var eyes = $head/eyes

#stamina bar properties
@onready var stamina = $player_ui/TextureProgressBar

func _input(event):
	if !cam: return
	if event is InputEventMouseMotion:
		cam.rotation.x -= event.relative.y * cam_speed
		cam.rotation.x = clamp(cam.rotation.x, -1.25, 1.5)
		self.rotation.y -= event.relative.x * cam_speed
		mouse_input = event.relative

func cam_tilt(input_x, delta):
		if cam:
			cam.rotation.z = lerp(cam.rotation.z, -input_x * cam_rotation_amount, 10 * delta)
		if hand:
			hand.rotation.z = lerp(hand.rotation.z, -input_x * hand_rotation_amount * 10, 10 * delta)

func hand_sway(delta):
	if is_on_floor():
		mouse_input = lerp(mouse_input, Vector2.ZERO, 10 * delta)
		hand.rotation.x = lerp(hand.rotation.x, mouse_input.y * hand_rotation_amount, 10 * delta)
		hand.rotation.y = lerp(hand.rotation.y, mouse_input.x * hand_rotation_amount, 10 * delta)

func hand_bob(vel : float, delta):
	if is_on_floor():
		if hand:
			if vel > 2:
				if SPEED == WALK_SPEED:
					var bob_amount : float = 0.01
					var bob_freq : float = 0.01
					hand.position.y = lerp(hand.position.y, hand_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount, 10 * delta)
					hand.position.x = lerp(hand.position.x, hand_pos.x + sin(Time.get_ticks_msec() * bob_freq * 0.5) * bob_amount, 10 * delta)
				if SPEED == SPRINT_SPEED:
					var bob_amount : float = 0.022
					var bob_freq : float = 0.022
					hand.position.y = lerp(hand.position.y, hand_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount, 10 * delta)
					hand.position.x = lerp(hand.position.x, hand_pos.x + sin(Time.get_ticks_msec() * bob_freq * 0.5) * bob_amount, 10 * delta)
			else:
				hand.position.y = lerp(hand.position.y, hand_pos.y, 10 * delta)
				hand.position.x = lerp(hand.position.x, hand_pos.x, 10 * delta)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hand_pos = hand.position
	#remove # for cutscene
	#SPEED = 0.0
	#can_sprint = false
	#JUMP_VELOCITY = 0.0
	#cam_speed = 0.0
	#await get_tree().create_timer(11.0, false).timeout
	SPEED = 3.0
	can_sprint = true
	JUMP_VELOCITY = 4.5
	cam_speed = 0.007

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		velocity += get_gravity() * 0.001
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	
	if can_sprint:
		if Input.is_action_pressed("sprint"):
			if stamina.value > 0:
				SPEED = SPRINT_SPEED
				head_bob_current_intensity = head_bob_sprint_intensity
				head_bob_index += head_bob_sprint_speed*delta
			else:
				SPEED = WALK_SPEED
				head_bob_current_intensity = head_bob_walk_intensity
				head_bob_index += head_bob_walk_speed*delta
		else:
			SPEED = WALK_SPEED
			head_bob_current_intensity = head_bob_walk_intensity
			head_bob_index += head_bob_walk_speed*delta
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if is_on_floor() && input_dir != Vector2.ZERO:
		head_bob_vector.y = sin(head_bob_index)
		head_bob_vector.x = sin(head_bob_index/2)+0.5
		eyes.position.y = lerp(eyes.position.y, head_bob_vector.y*(head_bob_current_intensity/2.0), delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bob_vector.x*head_bob_current_intensity, delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)

	move_and_slide()
	cam_tilt(input_dir.x, delta)
	hand_sway(delta)
	hand_bob(velocity.length(),delta)
