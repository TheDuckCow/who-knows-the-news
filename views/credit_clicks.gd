extends VBoxContainer

func _on_meta_clicked(meta):
	var res = OS.shell_open(meta)
	assert(res == OK)


func _on_firejam_logo_pressed():
	var res = OS.shell_open("https://itch.io/jam/godot-fire-charity-jam-1")
	assert(res == OK)


func _on_godot_logo_pressed():
	var res = OS.shell_open("https://godotengine.org/")
	assert(res == OK)


func _on_dcd_teaser_pressed():
	var res = OS.shell_open("https://theduckcow.itch.io/duckcowdrive-prototype")
	assert(res == OK)


func _on_back_to_menu_pressed():
	SceneTransition.load_menu_select()
