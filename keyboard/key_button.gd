extends Button

# warning-ignore:unused_signal
signal pressed_with_value(key)


func _ready():
	var res = connect("pressed", self, "_on_pressed_with_value")
	if res != OK:
		push_error("Failed to connect keyboard signal")


func _on_pressed_with_value():
	emit_signal("pressed_with_value", self.text.to_lower())
