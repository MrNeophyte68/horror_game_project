extends Node3D

@onready var time = get_tree().root.get_node("Level")

func _process(_delta: float) -> void:
	var remaining := maxf(time.game_timer.time_left, 0.0)
	update_clock(remaining)

func update_clock(remaining: float):
	var seconds_in_minute := fposmod(remaining, 60.0)
	var seconds_fraction := seconds_in_minute / 60.0
	var second_angle_deg := seconds_fraction * 360.0
	
	var minutes_fraction = 1.0 - remaining / time.TOTAL_SECONDS
	var minute_angle_deg = 300.0 - 120.0 * minutes_fraction
	
	var hours_fraction = 1.0 - remaining / time.TOTAL_SECONDS
	var hours_angle_deg = 210.0 - 30.0 * hours_fraction
	
	$clock_1/clock_1_arm_seconds.rotation_degrees.y = second_angle_deg
	$clock_1/clock_1_arm_minutes.rotation_degrees.y = minute_angle_deg
	$clock_1/clock_1_arm_hours.rotation_degrees.y = hours_angle_deg
