extends Control


func _ready():
	var this_view = get_viewport()
	this_view.connect("size_changed", self, "_on_screen_size_change")
	_on_screen_size_change()
	
	var res = $page_background.connect("pressed_home", self, "_on_back")
	if res != OK:
		push_error("Failed to connect home press in credits view")


func _on_screen_size_change():
	if Cache.is_compact_screen_size():
		$desktop_scroll.visible = false
		$mobile_scroll.visible = true
	else:
		$desktop_scroll.visible = true
		$mobile_scroll.visible = false

func _on_back():
	SceneTransition.load_menu_select()
