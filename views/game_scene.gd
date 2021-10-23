## Primary controller for the scramble game screen.
extends Control

const ScrambleState = preload("res://logic/scramble_state.gd")
const LoadScramble = preload("res://logic/load_scramble.gd")
const SolvedOverlay = preload("res://views/solved_overlay.tscn")
const mobile_desc_popup = preload("res://views/mobile_description_popup.tscn")

enum ScrambleSource {
	TEST,
	TUTORIAL,
	PRESET,
	DAILY_ARTICLE,
	TOPIC_ARTICLE
}

export(ScrambleSource) var source = ScrambleSource.TEST

onready var phrase_label := get_node("vscroll/VBoxContainer/phrase_state")
onready var keyboard := get_node("vscroll/VBoxContainer/keyboard")
onready var step_label := get_node("vscroll/VBoxContainer/status_bar/steps")
onready var steps_mobile := get_node("steps_mobile")
onready var publisher_name := get_node("vscroll/VBoxContainer/HBoxContainer2/pub_name")
onready var publish_date := get_node("vscroll/VBoxContainer/HBoxContainer2/pub_date")
onready var dscription := get_node("vscroll/VBoxContainer/description")
onready var topic_hint := get_node("vscroll/VBoxContainer/topic_hint")
onready var status_bar := get_node("vscroll/VBoxContainer/status_bar")

onready var spacer_to_del := get_node("vscroll/VBoxContainer/spacer_del_on_finish")

# Nodes for responsive display
onready var scroll_area := get_node("vscroll")
onready var _v_margin_initial = scroll_area.margin_top
onready var mobile_info := get_node("vscroll/VBoxContainer/HBoxContainer2/mobile_desc")


var state: ScrambleState
var article_link := "https://theduckcow.com" # Populated after load if any.

## Additioanl configuration vars, to be like proto "oneof" messages.

# Oneof: TEST
var test_index: int

# Oneof: TUTORIAL
var tutorial_index: int

# Oneof: PRESET
var preset_index: int

# Oneof: DAILY_ARTICLE, from database
var daily_artical_date: String

# Oneof: TOPIC_ARTICLE, local generation
var daily_article_country: String
var daily_article_language: String
var daily_article_topic: String


func _ready():
	keyboard.game_scene = self
	phrase_label.visible = false # In case of still loading.
	publisher_name.visible = false
	publish_date.visible = false
	topic_hint.text = "Category: Loading..."
	
	assert(keyboard.connect("key_pressed", self, "_on_key_pressed") == OK)
	
	var this_view = get_viewport()
	this_view.connect("size_changed", self, "_on_screen_size_change")
	_on_screen_size_change()


## Takes the current config and sets up the scene for scrambling.
func load_scramble():
	var solution
	var start
	match source:
		ScrambleSource.TEST:
			print("Load test scramble")
			var res = LoadScramble.load_test(0)
			solution = res[0]
			start = res[1]
			load_state(solution, start)
			keyboard.update_allowed_keys(solution)
			topic_hint.text = "Category: Test"
		ScrambleSource.TUTORIAL:
			var res = LoadScramble.load_tutorial(tutorial_index)
			solution = res[0]
			start = res[1]
			load_state(solution, start)
			show_tutorial_metadata()
			keyboard.update_allowed_keys(solution)
		ScrambleSource.TOPIC_ARTICLE:
			var url = LoadScramble.get_rss_article_url(
				daily_article_topic, daily_article_country, daily_article_language)
			var loader = LoadScramble.new()
			add_child(loader)
			var _http = loader.load_rss_article_request(url)
			topic_hint.text = "Loading article..."
			
			loader.connect("article_loaded", self, "load_state")
			loader.connect("article_load_failed", self, "load_failed")
			loader.connect("article_metadata", self, "show_article_metadata")
		_:
			load_failed("No match to scramble source")


func load_state(solution, start):
	if not solution or not start:
		load_failed("Solution or initial state is null")
		return
	state = ScrambleState.new(solution, start)
	keyboard.update_allowed_keys(solution)
	update_phrase_label()
	print(state.current_phrase)
	
	# Finally, make connections to this state object now created.
	var res = state.connect("state_updated_phrase", self, "update_phrase_label")
	if res != OK:
		push_error("Failed to connect phrase label")
	res = state.connect("puzzle_solved", self, "_on_puzzle_solved")
	if res != OK:
		push_error("Failed to connect puzzle solved")


func load_failed(reason:String):
	push_error("Failed to load scene with: %s" % reason)
	# TODO: Handle here, maybe with popup and timer to go back to main menu
	# to try again.
	topic_hint.text = "Failed to load article (%s)" % reason
	# SceneTransition.load_menu_select()


func _process(_delta):
	steps_mobile.text = get_timer_text()
	if not is_instance_valid(step_label):
		# At the end of the game, this section is dismissed.
		return
	step_label.text = get_timer_text()


func get_timer_text() -> String:
	var t
	if not state:
		return ""
	if state.is_solved:
		t = state.end_msec - state.start_msec
	else:
		t = OS.get_ticks_msec() - state.start_msec
	
	var minutes = int(floor(t/1000 / 60))
	var seconds = int(floor(t/1000 % 60))
	var txt = "%s %s, %02d:%02d" % [
		state.turns_taken,
		tr("swaps"),
		minutes,
		seconds
	]
	return txt


func _on_key_pressed(_chart):
	update_phrase_label()


func update_phrase_label():
	phrase_label.visible = true
	var tmp_phrase = []
	if not state: # E.g. if it failed to load.
		phrase_label.bbcode_text = ""
		return
	for i in range(len(state.current_phrase)):
		if state.current_phrase[i] == state.solution_phrase[i]:
			if state.current_phrase[i] == keyboard.mid_swap and false:
				# Warn that it's already a valid character, don't swap!
				tmp_phrase.append("[color=red]%s[/color]" % state.current_phrase[i])
			else:
				# Black for already correct charater;
				# have no color here so that word wrapping works on solution.
				tmp_phrase.append("%s" % state.current_phrase[i])
		else:
			if state.current_phrase[i] == keyboard.mid_swap and false:
				# Highlight the character being swapped.
				tmp_phrase.append("[color=blue]%s[/color]" % state.current_phrase[i])
			else:
				# Lighter color for not yet confirmed
				tmp_phrase.append("[color=gray]%s[/color]" % state.current_phrase[i])
	
	phrase_label.bbcode_text = "[center]%s[/center]" % PoolStringArray(tmp_phrase).join("")


func _on_puzzle_solved():
	var container = status_bar.get_node("../")
	keyboard.is_active = false
	var solve_popup := SolvedOverlay.instance()
	
	# Assign the "next" action.
	if source == ScrambleSource.TUTORIAL:
		if tutorial_index < len(LoadScramble.TUTORIAL_VALUES) - 1:
			solve_popup.next_mode = ScrambleSource.TUTORIAL
			solve_popup.tutorial_index = tutorial_index + 1
		else:
			solve_popup.next_mode = ScrambleSource.DAILY_ARTICLE
	else:
		solve_popup.next_mode = ScrambleSource.TOPIC_ARTICLE
	
	solve_popup.article_link = article_link
	solve_popup.stat_text = get_timer_text()
	spacer_to_del.queue_free()
	container.add_child_below_node(keyboard, solve_popup)
	status_bar.queue_free()
	keyboard.queue_free()


func show_article_metadata(article_info) -> void:
	print_debug(article_info)
	article_link = article_info["link"]
	publisher_name.bbcode_text = "[url=%s]%s[/url]" % [
		article_info["link"],
		article_info["source"]
	]
	publish_date.text = article_info["pubDate"]
	publisher_name.visible = true
	publish_date.visible = true
	topic_hint.text = "%s: %s" % [tr("Category"), daily_article_topic]
	dscription.text = article_info["description"] if "description" in article_info else "(no description fetched)"


func show_tutorial_metadata() -> void:
	publisher_name.bbcode_text = "[url=https://theduckcow.com]Moo-Ack! Productions[/url]"
	publisher_name.visible = true
	publish_date.text = ""
	publish_date.visible = true
	dscription.visible = true
	dscription.text = LoadScramble.TUTORIAL_META[tutorial_index][0]
	topic_hint.text = "%s: %s" % [
		tr("Category"),
		LoadScramble.TUTORIAL_META[tutorial_index][1]
	]


func _on_go_back_pressed():
	SceneTransition.load_menu_select()


func _on_show_answer_pressed():
	state.give_up()
	update_phrase_label()


func _on_publisher_info_meta_clicked(meta):
	assert(OS.shell_open(meta) == OK)


func _on_reset_pressed():
	state.reset()
	update_phrase_label()


## Create a more responsive display.
func _on_screen_size_change():
	if Cache.is_compact_screen_size():
		scroll_area.margin_top = _v_margin_initial - 30
		keyboard.use_small_font = true
		keyboard.generate_keyboard()
		if state:
			keyboard.update_allowed_keys(state.solution_phrase)
		dscription.visible = false
		steps_mobile.visible = true
		step_label.visible = false
		mobile_info.visible = true
	else:
		scroll_area.margin_top = _v_margin_initial
		keyboard.use_small_font = false
		keyboard.generate_keyboard()
		if state:
			keyboard.update_allowed_keys(state.solution_phrase)
		dscription.visible = true
		steps_mobile.visible = false
		step_label.visible = true
		mobile_info.visible = false


func _on_mobile_desc_pressed():
	var popup = mobile_desc_popup.instance()
	popup.description = dscription.text
	add_child(popup)
