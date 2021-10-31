extends Button

signal key_pressed(key)

onready var underline := get_node("underline")


func _ready():
	var res = connect("pressed", self, "key_pressed")
	if res != OK:
		push_error("failed to connect key press")


func key_pressed():
	print_debug("Pressed headline char ", text)
	emit_signal("key_pressed", self.text.to_lower())


func _on_headline_char_button_mouse_entered():
	# For debug only.
	#print("entered ", text)
	pass
