extends RichTextEffect
class_name ShakyEffect

# Use this tag in your text: [shaky amp=3 freq=12 speed=1.5 seed=0.0]...[/shaky]
var bbcode: StringName = "shaky"

func _process_custom_fx(char_fx: CharFXTransform):
	# Params (with defaults) read from the tag's attributes
	var amp: float = float(char_fx.env.get("amp", 2.0))      # pixels
	var freq: float = float(char_fx.env.get("freq", 10.0))   # Hz-ish
	var speed: float = float(char_fx.env.get("speed", 1.0))  # time scale
	var seed: float = float(char_fx.env.get("seed", 0.0))    # random-ish offset

	# Unique-ish phase per character so letters wobble differently
	var t := char_fx.elapsed_time * speed + float(char_fx.relative_index) * 0.17 + seed

	# 2D wobble
	char_fx.offset = Vector2(
		sin(t * freq) * amp,
		cos(t * (freq * 0.9)) * amp
	)

	# You could also add slight rotation using char_fx.transform if you want
	# var angle := sin(t * (freq * 0.5)) * 0.06
	# char_fx.transform = Transform2D(angle, Vector2.ZERO) * char_fx.transform
