## Primary controller for the scramble game screen.
extends Control

const ScrambleState = preload("res://logic/scramble_state.gd")
const LoadScramble = preload("res://logic/load_scramble.gd")
const SolvedOverlay = preload("res://views/solved_overlay.tscn")

enum ScrambleSource {
	TEST,
	TUTORIAL,
	PRESET,
	DAILY_ARTICLE,
	TOPIC_ARTICLE
}

export(ScrambleSource) var source = ScrambleSource.TEST

onready var phrase_label = get_node("VBoxContainer/phrase_state")
onready var keyboard = get_node("VBoxContainer/keyboard")
onready var step_label = get_node("VBoxContainer/top_spacer/HBoxContainer/steps")

var state: ScrambleState

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
	phrase_label.visible = false # In case of still loading.


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
		ScrambleSource.TUTORIAL:
			var res = LoadScramble.load_tutorial(tutorial_index)
			solution = res[0]
			start = res[1]
			load_state(solution, start)
		ScrambleSource.TOPIC_ARTICLE:
			var url = LoadScramble.get_rss_article_url(
				daily_article_topic, daily_article_country, daily_article_language)
			var loader = LoadScramble.new()
			add_child(loader)
			var _http = loader.load_rss_article_request(url)
			
			#yield(loader, "article_load_failed")
			#yield(loader, "article_loaded")
			#yield(http, "request_completed")
			
			loader.connect("article_loaded", self, "load_state")
			loader.connect("article_load_failed", self, "load_failed")
		_:
			load_failed("No match to scramble source")


func load_state(solution, start):
	state = ScrambleState.new(solution, start)
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


func _process(_delta):
	var t
	if not state:
		return
	if state.is_solved:
		t = state.end_msec - state.start_msec
	else:
		t = OS.get_ticks_msec() - state.start_msec
	var txt = "%s steps, %ss" % [
		state.turns_taken,
		int(t/1000)
	]
	step_label.text = txt


func update_phrase_label():
	phrase_label.visible = true
	phrase_label.bbcode_text = "[center]%s[/center]" % state.current_phrase


func _on_puzzle_solved():
	keyboard.is_active = false
	var solve_popup = SolvedOverlay.instance()
	add_child(solve_popup)
