extends Control

export(String) var file_name = "splash_screen"


func _ready():
	var _delay_screenshot = get_tree().create_timer(0.2)
	var res = _delay_screenshot.connect("timeout", self, "save_screenshot")
	assert(res == OK)


func save_screenshot():
	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	img.lock()
	var full_path = "res://screenshots/%s.png" % file_name
	var _res = img.save_png(full_path)
	print_debug("Made screenshot to:", ProjectSettings.globalize_path(full_path))
