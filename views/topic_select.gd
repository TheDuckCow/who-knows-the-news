extends Control

const PLACEHOLDER_TOPIC := "Environment"
const COUNTRIES = ["US", "CA", "UK", "AU", "SP", "MX"]
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

	if Cache.last_topic:
		input_topic.text = Cache.last_topic
	if Cache.last_topic_lang:
		input_country.selected = COUNTRIES.find(Cache.last_topic_lang)

	input_topic.grab_focus()
	var res = $page_background.connect("pressed_home", self, "_on_back")
	if res != OK:
		push_error("Failed to connect bg home button in topic scene")

	var topic_label = $scroll/VBoxContainer/topic_label
	topic_label.text = tr(topic_label.text)

	var footer = $scroll/VBoxContainer/footer
	footer.bbcode_text = tr(footer.bbcode_text)


func _process(_delta) -> void:
	if input_topic.has_focus() and Input.is_action_just_pressed("ui_accept"):
		print("Handled accept input")
		start_button.grab_focus()


func _on_start_pressed():
	Cache.last_topic = input_topic.text
	Cache.last_topic_lang = input_country.text
	SceneTransition.start_topic_scene(
		input_topic.text if input_topic.text != "" else PLACEHOLDER_TOPIC,
		COUNTRIES[input_country.selected] if input_country.selected != -1 else "US",
		Cache.language
	)

func _on_back():
	print_debug("Pressed home")
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


func _on_mouse_entered():
	pass # Replace with function body.
