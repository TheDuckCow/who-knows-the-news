extends Control

const GAME_SCENE = "res://views/game_scene.tscn"

onready var mobile_title := get_node("layout/VBoxContainer/game_title_mobile")

func _ready():
	SceneTransition.is_menu_screen = true
	#$layout/VBoxContainer/play_daily.grab_focus()
	$layout/VBoxContainer/custom_topic.grab_focus()
	if not SceneTransition.current_scene:
		# One time, afterwards it should self-assign.
		SceneTransition.current_scene = self
	
	var this_view = get_viewport()
	this_view.connect("size_changed", self, "_on_screen_size_change")
	_on_screen_size_change()


func _on_play_today_pressed():
	#SceneTransition.tbd
	pass


func _on_custom_topic_pressed():
	SceneTransition.load_topic_select_scene()


func _on_tutorial_pressed():
	SceneTransition.start_tutorial_scene(Cache.tutorial_stage)


func _on_link_clicked(meta):
	var res = OS.shell_open(meta)
	assert(res == OK)


func _on_screen_size_change():
	if Cache.is_compact_screen_size():
		mobile_title.visible = true
		$layout.margin_top = 50
	else:
		mobile_title.visible = false
		$layout.margin_top = 100


func _on_credits_pressed():
	SceneTransition.show_credits()
