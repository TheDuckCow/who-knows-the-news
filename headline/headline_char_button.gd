extends Button

signal key_pressed(key)

onready var underline := get_node("underline")
onready var focus_anim := get_node("focus_highlight")

func _ready():
	var res = connect("pressed", self, "key_pressed")
	if res != OK:
		push_error("failed to connect key press")


func key_pressed():
	emit_signal("key_pressed", self.text.to_lower())


func _on_headline_char_button_mouse_entered():
	if not disabled and focus_mode != FOCUS_NONE:
		grab_focus()


func _on_focus_entered():
	focus_anim.play("focus")


func _on_focus_exited():
	if focus_anim.get_current_animation():
		focus_anim.seek(0, true)
		focus_anim.stop()
