extends CharacterBody3D

var SPEED = 0.0
var JUMP_VELOCITY = 4.5
const WALK_SPEED = 3.0
const SPRINT_SPEED = 6.0
const CROUCH_SPEED = 1.5
var can_sprint = false
var can_crouch = true
var crouching = false

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
@onready var head = $head
const head_bob_crouch_intensity = 0.05
const head_bob_crouch_speed = 7.0

#stamina bar
@onready var ui = get_tree().root.get_node("Level/Player/player_ui")

#window vaulting
var near_window = false
var is_vaulting = false
@onready var raycast = $head/RayCast3D
var can_move = true

#variables used for abilities (camera)
@onready var stalker = $"../Stalker"
@onready var ability_cast = $head/AbilityCast
var ability_valid = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hand_pos = hand.position
	#can_move = false
	#can_sprint = false
	#await get_tree().create_timer(26.0, false).timeout
	can_move = true
	can_sprint = true
	SPEED = WALK_SPEED
	JUMP_VELOCITY = 4.5
	cam_speed = 0.007
	
	ability_cast.visible = false ## Hides ability cast when debugging because its ugly and annoying

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		velocity += get_gravity() * 0.001

	if can_move:
		if can_sprint:
			if Input.is_action_pressed("sprint"):
				if ui.stamina.value > 0:
					SPEED = SPRINT_SPEED
					head_bob_current_intensity = head_bob_sprint_intensity
					head_bob_index += head_bob_sprint_speed * delta
					head.position.y = lerp(head.position.y, 0.659, delta*6.0)
				else:
					SPEED = WALK_SPEED
					head_bob_current_intensity = head_bob_walk_intensity
					head_bob_index += head_bob_walk_speed * delta
			else:
				SPEED = WALK_SPEED
				head_bob_current_intensity = head_bob_walk_intensity
				head_bob_index += head_bob_walk_speed * delta
				
		if can_crouch:	
			if Input.is_action_just_pressed("crouch"):
				crouching = !crouching
		
		if crouching:
			SPEED = CROUCH_SPEED
			head_bob_current_intensity = head_bob_crouch_intensity
			head_bob_index += head_bob_crouch_speed * delta
			can_sprint = false
			head.position.y = lerp(head.position.y, -0.1, delta*6.0)
		elif !crouching and SPEED != SPRINT_SPEED:
			SPEED = WALK_SPEED
			can_sprint = true
			head.position.y = lerp(head.position.y, 0.659, delta*6.0)

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
			head_bob_vector.x = sin(head_bob_index / 2) + 0.5
			eyes.position.y = lerp(eyes.position.y, head_bob_vector.y * (head_bob_current_intensity / 2.0), delta * lerp_speed)
			eyes.position.x = lerp(eyes.position.x, head_bob_vector.x * head_bob_current_intensity, delta * lerp_speed)
		else:
			eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
			eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerp_speed)

		ability()
		cam_tilt(input_dir.x, delta)
		hand_sway(delta)
		hand_bob(velocity.length(), delta)
	else:
		# Prevent movement while in air if can_move is false
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
	
func _process(delta: float) -> void:
	if near_window and Input.is_action_pressed("interact") and ui.stamina.value >= 100 and raycast.can_vault:
		start_vault()
		raycast.can_vault = false

func start_vault():
	if is_vaulting:
		return
	is_vaulting = true
	ui.stamina.value -= 100.0
	ui.can_regen = false
	ui.s_timer = 0
	can_move = false
	
	# stop velocity so physics doesn't fight the tween
	velocity = Vector3.ZERO

	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam, "rotation", Vector3.ZERO, 0.1)
	
	# Calculate forward vault target (move ~2 meters forward)
	var forward_offset = -transform.basis.z.normalized() * 1.0  # forward is -Z in Godot
	var target_pos = global_position + forward_offset

	# Move player (use global_position, not global_transform:origin)
	tween.tween_property(self, "global_position", target_pos, 0.35)
	
	# Camera tilt (forward)
	tween.parallel().tween_property($head/eyes/Camera3D, "rotation_degrees:x", -20, 0.2)
	tween.parallel().tween_property($head/eyes/Camera3D, "rotation_degrees:z", -10, 0.2)

	# Reset tilt
	tween.tween_property($head/eyes/Camera3D, "rotation_degrees:x", 0, 0.2)
	tween.tween_property($head/eyes/Camera3D, "rotation_degrees:z", 0, 0.2)

	tween.finished.connect(func():
		is_vaulting = false
		can_move = true
	)

func _input(event):
	if !cam: return
	if can_move:
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
				if SPEED == CROUCH_SPEED:
					var bob_amount : float = 0.007
					var bob_freq : float = 0.007
					hand.position.y = lerp(hand.position.y, hand_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount, 10 * delta)
					hand.position.x = lerp(hand.position.x, hand_pos.x + sin(Time.get_ticks_msec() * bob_freq * 0.5) * bob_amount, 10 * delta)
			else:
				hand.position.y = lerp(hand.position.y, hand_pos.y, 10 * delta)
				hand.position.x = lerp(hand.position.x, hand_pos.x, 10 * delta)

# function that checks if an ability is valid and so can affect stalker
func ability() -> void:
	ability_valid = false # reset each tick
	
	for body in $head/AbilityArea.get_overlapping_bodies():
		if body == stalker:
			ability_cast.target_position = ability_cast.to_local(stalker.global_position).normalized() * 100.0
			ability_cast.force_raycast_update()
			
			if ability_cast.is_colliding() and ability_cast.get_collider() == stalker:
				ability_valid = true
				break # exit early if valid
