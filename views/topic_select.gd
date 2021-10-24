extends Control

const PLACEHOLDER_TOPIC := "Environment"
const COUNTRIES = ["US", "CA", "UK"]

onready var input_topic := get_node("VBoxContainer/topic_hb/topic")
onready var input_country := get_node("VBoxContainer/country")
onready var start_button := get_node("VBoxContainer/start")


func _ready():
	input_topic.placeholder_text = PLACEHOLDER_TOPIC
	for itm in COUNTRIES:
		input_country.add_item(itm)
	
	assert($page_background.connect("pressed_home", self, "_on_back") == OK)


func _on_start_pressed():
	SceneTransition.start_topic_scene(
		input_topic.text if input_topic.text != "" else PLACEHOLDER_TOPIC,
		COUNTRIES[input_country.selected] if input_country.selected != -1 else "US",
		Cache.language
	)

func _on_back():
	SceneTransition.load_menu_select()
