extends Control

const PLACEHOLDER_TOPIC := "Environment"
const LANGUAGES = [
	"en", 
	"es",
	"fr",
	"de"
]
const COUNTRIES = [
	"US", "CA", "UK"
]



onready var input_topic := get_node("VBoxContainer/topic")
onready var input_country := get_node("VBoxContainer/country")
onready var input_language := get_node("VBoxContainer/language")
onready var start_button := get_node("VBoxContainer/start")


func _ready():
	input_topic.placeholder_text = PLACEHOLDER_TOPIC
	for itm in LANGUAGES:
		input_language.add_item(itm)
	for itm in COUNTRIES:
		input_country.add_item(itm)


func _on_start_pressed():
	SceneTransition.start_topic_scene(
		input_topic.text if input_topic.text != "" else PLACEHOLDER_TOPIC,
		COUNTRIES[input_country.selected] if input_country.selected != -1 else "US",
		LANGUAGES[input_language.selected] if input_language.selected != -1 else "en"
		
	)
