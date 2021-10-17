extends Control

const ScrambleState = preload("res://logic/scramble_state.gd")
var state: ScrambleState

const LoadScramble = preload("res://logic/load_scramble.gd")

enum ScrambleSource {
	TEST,
	TUTORIAL,
	PRESET,
	DAILY_ARTICLE,
	RANDOM_ARTICLE
}

export(ScrambleSource) var source = ScrambleSource.TEST

onready var phrase_label = get_node("VBoxContainer/phrase_state")

## Additioanl configuration vars, to be like proto "oneof" messages.

# Oneof: TEST
var test_index: int

# Oneof: TUTORIAL
var tutorial_index: int

# Oneof: PRESET
var preset_index: int

# Oneof: DAILY_ARTICLE, from database
var daily_artical_date: String

# Oneof: RANDOM_ARTICLE, local generation
var daily_article_country: String
var daily_article_language: String
var daily_article_topic: String


func _ready():
	load_scramble()


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
			#[solution, start] = LoadScramble.load_test(0) # Doesn't work.
		_:
			print("No match to scramble source")

	state = ScrambleState.new(solution, start)
	update_phrase_label()
	print(state.current_phrase)


func update_phrase_label():
	phrase_label.bbcode_text = "[center]%s[/center]" % state.current_phrase

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
