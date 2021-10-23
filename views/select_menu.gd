extends Control

const GAME_SCENE = "res://views/game_scene.tscn"


func _ready():
	$layout/VBoxContainer/play_daily.grab_focus()
	if not SceneTransition.current_scene:
		# One time, afterwards it should self-assign.
		SceneTransition.current_scene = self
	
	


func _on_play_today_pressed():
	#assert(get_tree().change_scene(GAME_SCENE) == OK)
	#var trans = SceneTransition.instance()
	#add_child(trans)
	#_transition_rect.transition_to(GAME_SCENE)
	#SceneTransition.def
	pass


func _on_custom_topic_pressed():
	SceneTransition.load_topic_select_scene()


func _on_tutorial_pressed():
	SceneTransition.start_tutorial_scene(0)


func _on_link_clicked(meta):
	assert(OS.shell_open(meta) == OK)
