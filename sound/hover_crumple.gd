extends AudioStreamPlayer


func _on_mouse_entered():
	if Cache.sound_on:
		pitch_scale = 1 + randf() * 0.3
		play(0)
