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

#main level
@onready var level = get_tree().root.get_node("Level")

#fusebox
@onready var fusebox = get_tree().root.get_node("Level/map/Puzzle/fusebox")

#stamina bar
@onready var ui = get_tree().root.get_node("Level/Player/player_ui")

#window vaulting
var near_window = false
var is_vaulting = false
@onready var raycast = $head/RayCast3D
var can_move = true

#inventory
@onready var inventory: PlayerInventory = $Inventory
@onready var right_hand: Node3D = $head/eyes/hand
var current_item: Node3D = null
var equipped_slot: int = -1  # -1 means no item is currently equipped
var is_equipping: bool = false  # Prevents spamming
var item_list = ["lighter", "saw"]
var is_cutting: bool = false
@onready var inv_full_msg = $player_ui/CanvasLayer/inventory_full_msg
@onready var door_buy_msg = $player_ui/CanvasLayer/buy_door_message
@onready var remember_msg = $player_ui/CanvasLayer/RichTextLabel/AnimationPlayer
var vaultCount = 0
var spamming: bool = false

var staring: bool = false



func _ready() -> void:
	$player_ui/CanvasLayer/ColorRect.modulate.a = 0.0
	$head/RayCast3D/CanvasLayer/CutProgress.modulate.a = 0.0
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

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		velocity += get_gravity() * 0.001
	
	if $player_ui/CanvasLayer/buy_door_message.visible:
		$player_ui/CanvasLayer/saw_break_msg.visible = false
	
	if Input.is_action_just_pressed("interact2"):
		var tween = create_tween()
		tween.tween_property($head/eyes/hand/Clock, "position:y", -0.079, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	elif Input.is_action_just_released("interact2"):
		var tween = create_tween()
		tween.tween_property($head/eyes/hand/Clock, "position:y", -0.5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if Input.is_action_just_pressed("stare"):
		var tween = create_tween()
		tween.tween_property($player_ui/CanvasLayer/ColorRect, "modulate:a", 1.0, 1.0) # duration 0.5 seconds
		await get_tree().create_timer(1.0, false).timeout
		var tween1 = create_tween()
		tween1.tween_property($player_ui/CanvasLayer/ColorRect, "modulate:a", 0.0, 1.0)
		if Input.is_action_pressed("stare"):
			staring = true
			level.shadowCam.current = true
	elif Input.is_action_just_released("stare"):
		if staring:
			var tween = create_tween()
			tween.tween_property($player_ui/CanvasLayer/ColorRect, "modulate:a", 1.0, 1.0) # duration 0.5 seconds
			tween.tween_property($player_ui/CanvasLayer/ColorRect, "modulate:a", 0.0, 1.0)
			await get_tree().create_timer(1.0, false).timeout
			level.shadowCam.current = false
			level.cutsceneCam.current = false
			staring = false
		else:
			var tween = create_tween()
			tween.tween_property($player_ui/CanvasLayer/ColorRect, "modulate:a", 0.0, 1.0)
			staring = false
	
	if raycast.can_cut and near_window and is_cutting:
		$head/RayCast3D/CanvasLayer/CutProgress.value += delta * 40.0
		if $head/RayCast3D/CanvasLayer/CutProgress.value >= 500:
			_break_saw()
			$player_ui/CanvasLayer/saw_break_msg.visible = true
			await get_tree().create_timer(2.0, false).timeout
			$player_ui/CanvasLayer/saw_break_msg.visible = false

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

		cam_tilt(input_dir.x, delta)
		hand_sway(delta)
		hand_bob(velocity.length(), delta)
	else:
		# Prevent movement while in air if can_move is false
		direction = Vector3.ZERO
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
	
func _process(delta: float) -> void:
	if near_window and Input.is_action_pressed("interact") and ui.stamina.value >= 100 and raycast.can_vault:
		start_vault()
		raycast.can_vault = false

	for item in item_list:
		var n
		if current_item != null:
			n = current_item.get_node_or_null(item)
		if is_instance_valid(n):
			if n.name == "saw" and raycast.can_cut and near_window:
				if not current_item.get_node_or_null("AnimationPlayer").is_playing():
					current_item.get_node_or_null("AnimationPlayer").play("cutting")
					can_move = false
					is_cutting = true
					$head/RayCast3D/CanvasLayer/CutProgress.modulate.a = 0.2
			else:
				if current_item.get_node_or_null("AnimationPlayer").is_playing() and current_item.get_node_or_null("AnimationPlayer").current_animation == "cutting":
					current_item.get_node_or_null("AnimationPlayer").stop()
					can_move = true
					$head/RayCast3D/CanvasLayer/CutProgress.modulate.a = 0.0
					$head/RayCast3D/CanvasLayer/CutProgress.value = 0
					is_cutting = false

func start_vault():
	if is_vaulting:
		return
	vaultCount += 1
	if $anti_spam_vault.is_stopped():
		$anti_spam_vault.start()
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
		
		if event is InputEventKey and event.pressed and not event.echo:
			var slot := -1
			match event.keycode:
				KEY_1: slot = 0
				KEY_2: slot = 1
				KEY_3: slot = 2
			
			if slot != -1:
				toggle_item(slot)

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

func toggle_item(slot: int) -> void:
	if is_equipping:
		return  # Prevent rapid switching
		
	if equipped_slot == slot:
		unequip_item()
	else:
		equip_item(slot)

func equip_item(slot: int) -> void:
	is_equipping = true  # Lock input
	var item_scene = inventory.get_item(slot)
	if item_scene:
		if current_item:
			current_item.queue_free()

		current_item = item_scene.instantiate()
		right_hand.add_child(current_item)
		current_item.transform = Transform3D.IDENTITY  # Reset position/rotation
		equipped_slot = slot
		
		var anim_player = current_item.get_node_or_null("AnimationPlayer")
		if anim_player:
			if anim_player.has_animation("equip"):
				anim_player.play("equip")
				await get_tree().create_timer(2.0, false).timeout
	is_equipping = false  # Unlock input

func unequip_item() -> void:
	is_equipping = true  # Lock input
	if current_item:
		var anim_player = current_item.get_node_or_null("AnimationPlayer")

		if anim_player:
			# Play 'equip' in reverse to hide it smoothly
			if anim_player.has_animation("unequip"):
				anim_player.play("unequip")
				await anim_player.animation_finished
				
		current_item.queue_free()
		current_item = null
		equipped_slot = -1
	is_equipping = false  # Unlock input

func add_item_to_inventory(item_scene: PackedScene) -> bool:
	for i in range(inventory.inventory.size()):
		if inventory.inventory[i] == null:
			inventory.inventory[i] = item_scene
			return true  # success
	print("Inventory full!")
	return false  # no empty slot found

func _break_saw():
	# stop cutting anim if needed
	var ap := current_item.get_node_or_null("AnimationPlayer") if current_item else null
	if ap and ap.is_playing() and ap.current_animation == "cutting":
		ap.stop()

	# remove in-hand instance
	if current_item:
		current_item.queue_free()
		current_item = null

	# remove from inventory (this is the part you were missing)
	if equipped_slot != -1 and equipped_slot < inventory.inventory.size():
		inventory.inventory[equipped_slot] = null
		equipped_slot = -1

	# reset cutting/ui state
	can_move = true
	is_cutting = false
	$head/RayCast3D/CanvasLayer/CutProgress.modulate.a = 0.0


func _on_anti_spam_vault_timeout() -> void:
	if vaultCount >= 3:
		#print("stop spamming")
		spamming = true
		vaultCount = 0
	else:
		#print("you are not spamming")
		spamming = false
		vaultCount = 0
		
