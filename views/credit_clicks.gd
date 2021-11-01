extends VBoxContainer

export(String) var page

func _ready():
	if page == "left":
		$CR_TY_2.bbcode_text = tr($CR_TY_2.bbcode_text)
		$HBoxContainer2/CR_MADE_FOR.bbcode_text = tr($HBoxContainer2/CR_MADE_FOR.bbcode_text)
		$HBoxContainer/CR_GODOT_WHAT.bbcode_text = tr($HBoxContainer/CR_GODOT_WHAT.bbcode_text)
		$CR_ASSETS_BB.bbcode_text = tr($CR_ASSETS_BB.bbcode_text)
	else:
		$CR_AS_IS_BB.bbcode_text = tr($CR_AS_IS_BB.bbcode_text)
		$CR_OTHER_BB.bbcode_text = tr($CR_OTHER_BB.bbcode_text)
		$CR_OTHER_BB.bbcode_text = tr($CR_OTHER_BB.bbcode_text)


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
