## Save state across the game when needed, such as for language.
extends Node

const USER_SETTINGS_PATH = "user://know_the_news_save.cfg"

# warning-ignore:unused_signal
signal language_update(locale)

const LANGUAGES = [
	"en", 
	"es",
	#"fr",
]

var max_tutorial_stage_finished := -1
var language := "en"
var sound_on := true

# Structure of {url:String : {steps:int, time:int, gave_up:bool}}
# gave_up is assumed true until puzzle is solved.
var headlines_played := {}
# Structure of {"YYYY-MM-DD":SolutionPhrase}
var daily_completed := {}
var tutorial_stage:int = 0
var last_topic := ""
var last_topic_lang := ""

# To skip double updates
var local_update := false


func _ready():
	var res = connect("language_update", self, "_on_language_update")
	if res != OK:
		push_error("Failed to connect language changer")
	
	load_local_game()


func _on_language_update(locale):
	language = locale
	TranslationServer.set_locale(language)
	save_local_game()
	SceneTransition.load_menu_select()


func is_compact_screen_size() -> bool:
	# OS.get_windows_size()
	#var screen_size = get_viewport().get_rect().size
	var screen_size = OS.window_size
	return screen_size.x < 640 or screen_size.y < 480


func udpate_session_solve(state:ScrambleState) -> void:
	headlines_played[state.solution_phrase] = {
		"current": state.current_phrase if state.current_phrase != state.solution_phrase else "",
		"swaps": state.turns_taken,
		"time": state.end_msec - state.start_msec if state.end_msec else 0,
		"gave_up": not state.is_solved,
		"date": get_today()
	}
	save_local_game()


func get_today() -> String:
	var date = OS.get_datetime()
	return "%s-%s-%s" % [date["year"], date["month"], date["day"]]


func save_local_game():
	var save_data := {
		"language": language,
		"sound_on": sound_on,
		"max_tutorial_stage_finished": max_tutorial_stage_finished,
		"headlines_played": headlines_played,
		"last_topic_lang": last_topic_lang
	}
	
	var file = File.new()
	file.open(USER_SETTINGS_PATH, File.WRITE)
	file.store_var(save_data)
	file.close()


func load_local_game():
	var file = File.new()
	if not file.file_exists(USER_SETTINGS_PATH):
		print_debug("No save found, save local now")
		save_local_game()
		file.close()
		return
	
	file.open(USER_SETTINGS_PATH, File.READ)
	var raw_data = file.get_var()
	file.close()
	
	#print_debug(raw_data)
	if not raw_data:
		push_warning("No data found in save_data")
		return
	elif not raw_data is Dictionary:
		push_warning("Save data is not in dict format")
		return
	
	var save_data:Dictionary = raw_data
	var loaded_any := false
	
	if save_data.has("language"):
		language = save_data["language"]
		TranslationServer.set_locale(language)
		loaded_any = true
	if save_data.has("sound_on"):
		sound_on = save_data["sound_on"]
		loaded_any = true
	if save_data.has("max_tutorial_stage_finished"):
		max_tutorial_stage_finished = save_data["max_tutorial_stage_finished"]
		if max_tutorial_stage_finished < 3:
			tutorial_stage = max_tutorial_stage_finished + 1
		loaded_any = true
	if save_data.has("headlines_played"):
		headlines_played = save_data["headlines_played"]
		loaded_any = true
	if save_data.has("last_topic_lang"):
		last_topic_lang = save_data["last_topic_lang"]
		loaded_any = true
	
	if not loaded_any:
		push_warning("Did not load any data")
	else:
		print_debug("Loaded past user game data")
