extends Control


onready var date := get_node("VBoxContainer/HBoxContainer2/date")
onready var language := get_node("VBoxContainer/HBoxContainer/language")

# Called when the node enters the scene tree for the first time.
func _ready():
	for itm in Cache.LANGUAGES:
		language.add_item(itm)
	language.icon = load("res://images/languages/%s.png" % Cache.language)
	
	var date_dict = {
		1: "Jan",
		2: "Feb",
		3: "Mar",
		4: "Apr",
		5: "May",
		6: "Jun",
		7: "Jul",
		8: "Aug",
		9: "Sep",
		10: "Oct",
		11: "Nov",
		12: "Dec",
	}
	var dt := OS.get_date()
	date.text = "%s. %s, %s" % [date_dict[dt["month"]], dt["day"], dt["year"]]


func _on_top_credit_meta_clicked(meta):
	print(meta)
	var res = OS.shell_open(meta)
	if res != OK:
		push_error("Failed to open click")


func _on_lang_update(index:int):
	language.icon = load("res://images/languages/%s.png" % Cache.LANGUAGES[index])
	Cache.emit_signal("language_update", Cache.LANGUAGES[index])