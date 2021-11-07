extends Control

const DAYS = [
	'Sunday',
	'Monday',
	'Tuesday',
	'Wednesday',
	'Thursday',
	'Friday',
	'Saturday'
]

onready var past_daily_desktop := get_node("Container/VBoxContainer/past_daily_desktop")
onready var past_daily_mobile := get_node("Container/VBoxContainer/past_daily_mobile")
onready var no_tutorial := get_node("Container/VBoxContainer/no_tutorial")
onready var play_daily := get_node("Container/VBoxContainer/play_daily")
onready var play_another := get_node("Container/VBoxContainer/another_puzzle")

# For translation only
onready var ready_bb  := get_node("Container/VBoxContainer/ready_bb")
onready var general_text := get_node("Container/VBoxContainer/general_text")

var today_date: String


func _ready():
	today_date = Cache.get_today()
	print_debug(Cache.max_tutorial_stage_finished)
	if Cache.max_tutorial_stage_finished >= 2:
		no_tutorial.visible = false
	else:
		no_tutorial.bbcode_text = tr(no_tutorial.bbcode_text)
	
	ready_bb.bbcode_text = tr(ready_bb.bbcode_text)
	general_text.bbcode_text = tr(general_text.bbcode_text)
	
	print_debug("Check if today's date already found:")
	print(today_date)
	print(Cache.daily_completed)
	if Cache.daily_completed.has(today_date):
		play_daily.text = "%s %s" % [
			tr("DLY_ALREADY_DONE"), today_date]
		play_daily.disabled = true
		play_daily.focus_mode = Button.FOCUS_NONE
		play_another.visible = true
	else:
		play_another.visible = false
	
	# Not ready yet, idea is to pull from user daily stats.
	#load_daily_stats()
	
	var res = $page_background.connect("pressed_home", SceneTransition, "load_menu_select")
	if res != OK:
		push_error("Failed to connect bg home button in topic scene")


func load_daily_stats():
	for i in range(DAYS.size()):
		var btn_d = Button.new()
		btn_d.text = "Play %s" % DAYS[i]
		past_daily_desktop.add_child(btn_d)


func _on_play_daily_pressed():
	SceneTransition.start_daily_puzzle(today_date)


func _on_RichTextLabel2_meta_clicked(meta):
	if meta == "tutorial":
		SceneTransition.start_tutorial_scene(Cache.tutorial_stage)
	else:
		var res = OS.shell_open(meta)
		assert(res == OK)


func _on_another_puzzle_pressed():
	SceneTransition.load_topic_select_scene()
