extends VBoxContainer

func _on_meta_clicked(meta):
	assert(OS.shell_open(meta) == OK)


func _on_firejam_logo_pressed():
	assert(OS.shell_open("https://itch.io/jam/godot-fire-charity-jam-1") == OK)


func _on_godot_logo_pressed():
	assert(OS.shell_open("https://godotengine.org/") == OK)


func _on_dcd_teaser_pressed():
	assert(OS.shell_open("https://theduckcow.itch.io/duckcowdrive-prototype") == OK)


func _on_back_to_menu_pressed():
	SceneTransition.load_menu_select()
