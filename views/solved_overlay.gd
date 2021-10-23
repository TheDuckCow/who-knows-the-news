extends Control

var GS = load("res://views/game_scene.gd")
const SELECT_SCREEN = "res://views/select_menu.tscn"

onready var next_button := get_node("anim_control/Control/HBoxContainer/next_button")
onready var stats_label := get_node("anim_control/Control/Control/VBoxContainer/stats")

var stat_text := ""
var next_mode = GS.ScrambleSource.TOPIC_ARTICLE
var article_link := ""

# Oneof: TUTORIAL
var tutorial_index: int


func _ready():
	next_button.grab_focus()
	stats_label.text = stat_text
	if next_mode == GS.ScrambleSource.DAILY_ARTICLE:
		next_button.text = "Play daily article"
	elif next_mode == GS.ScrambleSource.TUTORIAL:
		next_button.text = "Next tutorial"
	else:
		next_button.text = "New puzzle"

func _on_menu_pressed():
	SceneTransition.load_menu_select()


func _on_next_pressed():
	print_debug("Next press, mode: %s" % next_mode)
	if next_mode == GS.ScrambleSource.DAILY_ARTICLE:
		SceneTransition.load_daily_puzzle()
	elif next_mode == GS.ScrambleSource.TUTORIAL:
		SceneTransition.start_tutorial_scene(tutorial_index)
	else:
		SceneTransition.load_topic_select_scene()


func _on_open_article_pressed():
	var _res = OS.shell_open(article_link)
