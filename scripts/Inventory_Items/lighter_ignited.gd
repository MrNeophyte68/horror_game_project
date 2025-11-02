extends OmniLight3D

@export var noise: NoiseTexture3D
var time_passed := 0.0
var sampled_noise

func _process(delta):
	time_passed += delta
	
	sampled_noise = noise.noise.get_noise_1d(time_passed)
	sampled_noise = abs(sampled_noise)
	
	light_energy = sampled_noise + 1.0
	pass
	
