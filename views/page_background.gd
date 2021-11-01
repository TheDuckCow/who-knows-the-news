extends Control

signal pressed_home

onready var date := get_node("VBoxContainer/HBoxContainer2/date")
onready var language := get_node("VBoxContainer/HBoxContainer/language")
onready var sound_toggle := get_node("VBoxContainer/HBoxContainer/sound_toggle")

# Vars for responsible display.
onready var h_logo := get_node("VBoxContainer/HBoxContainer/logo")
onready var h_title := get_node("VBoxContainer/HBoxContainer/game_title")
onready var h_credit := get_node("VBoxContainer/HBoxContainer2/top_credit")
onready var h_date := get_node("VBoxContainer/HBoxContainer2/date")
onready var h_top_bar := get_node("VBoxContainer/top_separator")


func _ready():
	set_sound_button()
	for itm in Cache.LANGUAGES:
		language.add_item(itm)
	#language.text = Cache.language
	language.selected = Cache.LANGUAGES.find(Cache.language)
	language.icon = load("res://images/languages/%s.png" % Cache.language)
	
	var date_dict = {
		1: "M_JAN",
		2: "M_FEB",
		3: "M_MAR",
		4: "M_APR",
		5: "M_MAY",
		6: "M_JUN",
		7: "M_JUL",
		8: "M_AUG",
		9: "M_SEP",
		10: "M_OCT",
		11: "M_NOV",
		12: "M_DEC",
	}
	var dt := OS.get_date()
	date.text = "%s. %s, %s" % [tr(date_dict[dt["month"]]), dt["day"], dt["year"]]
	
	var this_view = get_viewport()
	this_view.connect("size_changed", self, "_on_screen_size_change")
	_on_screen_size_change()
	
	h_credit.bbcode_text = tr(h_credit.bbcode_text)


func _on_top_credit_meta_clicked(meta):
	print(meta)
	var res = OS.shell_open(meta)
	if res != OK:
		push_error("Failed to open click")


func _on_lang_update(index:int):
	language.icon = load("res://images/languages/%s.png" % Cache.LANGUAGES[index])
	Cache.emit_signal("language_update", Cache.LANGUAGES[index])


func _on_sound_toggle_pressed():
	Cache.sound_on = not Cache.sound_on
	set_sound_button()


func set_sound_button():
	if Cache.sound_on:
		sound_toggle.texture_hover = load("res://images/sound_on.png")
		sound_toggle.texture_normal = load("res://images/sound_on_hover.png")
		sound_toggle.texture_pressed = load("res://images/sound_off_press.png")
	else:
		sound_toggle.texture_hover = load("res://images/sound_off.png")
		sound_toggle.texture_normal = load("res://images/sound_off_hover.png")
		sound_toggle.texture_pressed = load("res://images/sound_on_press.png")


func _on_screen_size_change():
	#var screen_size = get_viewport_rect().size
	if Cache.is_compact_screen_size(): # screen_size.x < 640 and screen_size.y < 580:
		# Small in both directions
		# h_logo.visible = false
		h_title.visible = false
		h_credit.visible = false
		h_date.visible = false
		h_top_bar.visible = false
#	elif screen_size.x < 640 and screen_size.y > 580:
#		# Small in just x direction
#		h_logo.visible = false
#		h_title.visible = false
#		h_credit.visible = false
#		h_date.visible = true
#		h_top_bar.visible = true
#	elif screen_size.y < 580:
#		# Small in just y direction.
#		h_logo.visible = true
#		h_title.visible = true
#		h_credit.visible = true
#		h_date.visible = false
#		h_top_bar.visible = false
	else:
		# h_logo.visible = true
		h_title.visible = true
		h_credit.visible = true
		h_date.visible = true
		h_top_bar.visible = true


func _on_logo_pressed():
	print_debug("Pressed home [from bg scene]")
	emit_signal("pressed_home")
