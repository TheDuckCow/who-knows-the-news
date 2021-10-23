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
var sound_on := true


func _ready():
	assert(connect("language_update", self, "_on_language_update") == OK)


func _on_language_update(locale):
	language = locale

func is_compact_screen_size() -> bool:
	# OS.get_windows_size()
	#var screen_size = get_viewport().get_rect().size
	var screen_size = OS.window_size
	return screen_size.x < 640 or screen_size.y < 480
