extends CharacterBody3D

enum States { ROAMING, STALKING, CHASING, SEARCHING }

var state: States = States.ROAMING

@export var patrol_destinations: Array[Node3D]
@export var stalking_max_time: float = 20.0
@export var stalking_increase_rate: float = 1.0
@export var stalking_decrease_rate: float = 1.0

@onready var player: CharacterBody3D = $"../Player"
@onready var detection_area: Area3D = $DetectionArea
@onready var detection_cast: RayCast3D = $DetectionCast
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var rng := RandomNumberGenerator.new()

var speed := 3.0
var destination: Node3D
var destination_position: Vector3
var destination_value: int = -1
var spotted: bool = false
var stalking_meter_ended: bool = false
var stalking_time: float = stalking_max_time

func _ready() -> void:
	pick_destination()


func pick_destination(exclude_index: int = -1) -> void:
	var idx := rng.randi_range(0, patrol_destinations.size() - 1)
	if idx == exclude_index:
		idx = (idx + 1) % patrol_destinations.size()
	
	destination_value = idx
	destination = patrol_destinations[idx]
	destination_position = destination.global_position  # cache position


func update_target_location() -> void:
	nav_agent.target_position = destination_position


func _process(delta: float) -> void:
	if state == States.ROAMING and destination:
		var look_dir := lerp_angle(
			deg_to_rad(global_rotation_degrees.y),
			atan2(-velocity.x, -velocity.z),
			0.5
		)
		global_rotation_degrees.y = rad_to_deg(look_dir)
		update_target_location()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if state == States.ROAMING:
		_process_roaming()
	elif state == States.STALKING:
		_process_stalking(delta)
	elif state == States.CHASING:
		_process_chasing()


func _process_roaming() -> void:
	if not destination:
		return
	var next := nav_agent.get_next_path_position()
	var new_velocity := (next - global_position).normalized() * speed
	velocity = velocity.move_toward(new_velocity, 0.25)
	move_and_slide()


func _process_stalking(delta: float) -> void:
	_face_target(player.global_position)
	stalking_meter_ended = false
	
	if spotted:
		# decrease timer 
		stalking_time -= stalking_decrease_rate * delta
		if stalking_time <= 0.0:
			stalking_time = 0.0
			stalking_meter_ended = true
			state = States.CHASING
			print("Stalking finished")
			
		print(stalking_time)
		velocity = Vector3.ZERO
		
	else:
		if not stalking_meter_ended:
			stalking_time += stalking_increase_rate * delta
			stalking_time = min(stalking_time, stalking_max_time)
			
		nav_agent.target_position = player.global_position
		velocity = _get_direction_to_target() * (speed + 6.0)
	
	move_and_slide()

func _process_chasing() -> void:
	nav_agent.target_position = player.global_position
	velocity = _get_direction_to_target() * speed

	var target_pos := player.global_position
	target_pos.y = global_position.y
	_face_target(target_pos)

	move_and_slide()


func _get_direction_to_target() -> Vector3:
	var next := nav_agent.get_next_path_position()
	return (next - global_position).normalized()


func _face_target(target: Vector3, tolerance := 0.01) -> void:
	var direction := (target - global_position).normalized()
	if direction.dot(global_transform.basis.z) < 1.0 - tolerance:
		look_at(target, Vector3.UP)


func _on_detection_timer_timeout() -> void:
	for body in detection_area.get_overlapping_bodies():
		if body == player:
			detection_cast.look_at(player.global_position, Vector3.UP)
			detection_cast.force_raycast_update()
			
			if stalking_meter_ended == false:
				if detection_cast.is_colliding() and detection_cast.get_collider() == player:
					detection_cast.debug_shape_custom_color = Color(1, 0, 0)
					state = States.STALKING
					spotted = true
				else:
					detection_cast.debug_shape_custom_color = Color(0, 1, 0)
					spotted = false
			return  #exit early after finding player

func _on_back_detection_timer_timeout() -> void:
	for body in $BackDetectionArea.get_overlapping_bodies():
		if body == player:
			print(body)
			$BackDetectionCast.look_at(player.global_position, Vector3.UP)
			$BackDetectionCast.force_raycast_update()
			
			if stalking_meter_ended == false:
				if $BackDetectionCast.is_colliding() and $BackDetectionCast.get_collider() == player:
					if $BackTimer.is_stopped():
						$BackTimer.start()
					$BackDetectionCast.debug_shape_custom_color = Color(0, 0, 1)
					print($BackTimer.time_left)
				else:
					if not $BackTimer.is_stopped():
						$BackTimer.stop()
						$BackTimer.start()
					$BackDetectionCast.debug_shape_custom_color = Color(0, 1, 0)
			return

func _on_back_timer_timeout() -> void:
	state = States.STALKING
