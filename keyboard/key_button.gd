extends Button

# warning-ignore:unused_signal
signal pressed_with_value(key)

var size := 0 setget _on_set_size, _on_get_size

func _ready():
	var res = connect("pressed", self, "_on_pressed_with_value")
	if res != OK:
		push_error("Failed to connect keyboard signal")


func _on_pressed_with_value():
	emit_signal("pressed_with_value", self.text.to_lower())


func _on_set_size(value):
	size = value
	if size > 0:
		rect_min_size.x = size
		rect_min_size.y = size


func _on_get_size():
	return size
