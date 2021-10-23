extends AudioStreamPlayer

# use as if public var: pitch_scale

func _on_mouse_entered():
	pitch_scale = 1 + randf() * 0.3
	play(0)
