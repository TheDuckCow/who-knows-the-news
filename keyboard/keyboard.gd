## Defines the overall size of the interactiv keyboard.
extends Control

enum LayoutType {
	US
}

onready var KeyButton = preload("res://keyboard/key_button.tscn")

# Keyboard layouts, where r0 = first, top row of keys.
# Intent is to only show keys that would be swappable.
# TODO: Create special keys, such as ".." for spacer.
const LAYOUT = {
	LayoutType.US: [
		["Q","W","E","R","T","Y","U","I","O","P"],
		["A","S","D","F","G","H","J","K","L"],
		["Z","X","C","V","B","N","M"],
	]
}

var use_layout = LayoutType.US
onready var row_container = $rows


func _ready():
	generate_keyboard()


## Generate or regenerate the overall keyboard.
func generate_keyboard():
	for row in row_container.get_children():
		# Disconnect needed?
		row.queue_free()
	
	for row in LAYOUT[use_layout]:
		var new_row = HBoxContainer.new()
		row_container.add_child(new_row)
		var start_spacer = Control.new()
		start_spacer.size_flags_horizontal = true
		var end_spacer = Control.new()
		new_row.add_child(start_spacer)
		for key in row:
			add_key_to_row(new_row, key)
		new_row.add_child(end_spacer)
	

## Populate a single row of keys, connecting signals as needed.
func add_key_to_row(parent_row:HBoxContainer, key:String):
	var new_key = KeyButton.instance()
	new_key.text = key
	parent_row.add_child(new_key)
