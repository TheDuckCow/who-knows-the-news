extends Control

const PLACEHOLDER_TOPIC := "Environment"
const COUNTRIES = ["US", "CA", "UK"]
const ALLOWS_CHARS = "[A-Za-z-']"

const RANDOM_TOPICS = [
	"Environment",
	"Politics",
	"Government",
	"Entertainment",
	"Arts",
	"Technology",
	"Health",
	"Games",
	"Sports",
]

onready var input_topic := get_node("scroll/VBoxContainer/topic_hb/topic")
onready var input_country := get_node("scroll/VBoxContainer/HBoxContainer/country")
onready var start_button := get_node("scroll/VBoxContainer/start")


func _ready():
	input_topic.placeholder_text = PLACEHOLDER_TOPIC
	for itm in COUNTRIES:
		input_country.add_item(itm)
	
	input_topic.grab_focus()
	assert($page_background.connect("pressed_home", self, "_on_back") == OK)


func _on_start_pressed():
	SceneTransition.start_topic_scene(
		input_topic.text if input_topic.text != "" else PLACEHOLDER_TOPIC,
		COUNTRIES[input_country.selected] if input_country.selected != -1 else "US",
		Cache.language
	)

func _on_back():
	SceneTransition.load_menu_select()


func _on_topic_text_changed(new_text):
	var init_cursor_pos = input_topic.caret_position
	var category = ''
	var regex = RegEx.new()
	regex.compile(ALLOWS_CHARS)
	for valid_character in regex.search_all(new_text):
		category += valid_character.get_string()
	input_topic.set_text(category)
	input_topic.caret_position = init_cursor_pos


func _on_random_topic_pressed():
	var ind
	var new_category
	if input_topic.text in RANDOM_TOPICS:
		ind = randi() % (RANDOM_TOPICS.size() -1)
	else:
		ind = randi() % RANDOM_TOPICS.size()
	
	if input_topic.text == RANDOM_TOPICS[ind]:
		new_category = RANDOM_TOPICS[ind + 1]
	else:
		new_category = RANDOM_TOPICS[ind]
	input_topic.set_text(new_category)
