extends Node3D

@onready var player = $"../../../.."
@onready var flash = $"../../Camera3D/Flash" 
var flash_duration: float = 0.2 
var flash_active: bool = false
var ability_cooldown: float = 0.0 
var count: int = 5

func _process(delta: float) -> void:
	# Update ability cooldown
	if ability_cooldown >= 0.0:
		ability_cooldown -= delta
	
	# Flash duration cooldown
	if flash_active:
		flash_duration -= delta
		if flash_duration <= 0.0:
			flash_active = false
			flash.visible = false
			flash_duration = 0.2
	
	use_camera()

func use_camera():
	if Input.is_action_just_pressed("ability") and is_visible_in_tree() and count > 0 and ability_cooldown <= 0.0:
		_trigger_flash_effect()
		if player.ability_valid:
			for body in $"../../../AbilityArea".get_overlapping_bodies():
				print("Hit body:", body.name, " groups:", body.get_groups())
				if body.is_in_group("Stalker"):
					body.stunned = true

func _trigger_flash_effect():
	if flash_active:
		return # Prevent re-triggering if already flashing
		
	flash_active = true
	ability_cooldown = 0.2
	count -=1
	flash.visible = true
	flash.light_energy = 10.0
	
	# tween to make flash more smooth
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(0.1)
