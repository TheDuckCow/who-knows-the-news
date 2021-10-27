extends Panel

onready var text_box := get_node("VBoxContainer/desc_popup")
onready var tween := get_node("Tween")

var description: String

func _ready():
	text_box.text = description
	tween.interpolate_property(self, "modulate:a",
		0, 1, 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func _on_close_popup_pressed():
	tween.interpolate_property(self, "modulate:a",
		1, 0, 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	var res = tween.connect("tween_completed", self, "on_tween_finish")
	assert(res == OK)
	tween.start()


func on_tween_finish(_object: Object, _key: NodePath):
	queue_free()
