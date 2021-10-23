## Save state across the game when needed, such as for language.
extends Node

# warning-ignore:unused_signal
signal language_update(locale)

const LANGUAGES = [
	"en", 
	"es",
	"fr",
	"de"
]

var language = "en"
var solved_urls = []


func _ready():
	assert(connect("language_update", self, "_on_language_update") == OK)


func _on_language_update(locale):
	language = locale
