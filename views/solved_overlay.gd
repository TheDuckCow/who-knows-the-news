extends Control

var GS = load("res://views/game_scene.gd")
const SELECT_SCREEN = "res://views/select_menu.tscn"

onready var next_button := get_node("anim_control/Control/HBoxContainer/next_button")
onready var stats_label := get_node("anim_control/Control/VBoxContainer/PanelContainer2/stats")
onready var victory_audio := get_node("victory")
onready var open_article := get_node("anim_control/Control/open_article")
onready var solved_bb := get_node("anim_control/Control/VBoxContainer/PanelContainer/puzzle_solved_static")

var stat_text := ""
var next_mode = GS.ScrambleSource.TOPIC_ARTICLE
var article_link := ""

# Oneof: TUTORIAL
var tutorial_index: int


func _ready():
	stats_label.text = stat_text
	if next_mode == GS.ScrambleSource.DAILY_ARTICLE:
		next_button.text = tr("UI_TUT_FINISH")
	elif next_mode == GS.ScrambleSource.TUTORIAL:
		next_button.text = tr("UI_NEXT_TUT")
		open_article.visible = false
	else:
		next_button.text = tr("UI_NEW_PUZZLE")
	if Cache.sound_on:
		victory_audio.play(0)
	next_button.call_deferred("grab_focus")

	solved_bb.bbcode_text = tr(solved_bb.bbcode_text)


func _on_menu_pressed():
	SceneTransition.load_menu_select()


func _on_next_pressed():
	print_debug("Next press, mode: %s" % next_mode)
	if next_mode == GS.ScrambleSource.DAILY_ARTICLE:
		# SceneTransition.load_daily_puzzle() # Not ready.
		SceneTransition.load_topic_select_scene()
	elif next_mode == GS.ScrambleSource.TUTORIAL:
		SceneTransition.start_tutorial_scene(tutorial_index)
	else:
		SceneTransition.load_topic_select_scene()


func _on_open_article_pressed():
	var _res = OS.shell_open(article_link)
