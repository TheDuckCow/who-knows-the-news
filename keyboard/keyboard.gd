## Defines the overall size of the interactiv keyboard.
extends Control

const LoadScramble = preload("res://logic/load_scramble.gd")

enum LayoutType {
	US
}

# Fired when a staged swap has begun
# warning-ignore:unused_signal
signal key_pressed(character)

onready var KeyButton = preload("res://keyboard/key_button.tscn")
onready var game_scene = get_node("../../")

# Way to disable the keyboard if needed, e.g. on game win.
var is_active := true

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

# To indicate if in the middle of swapping 2 characters, awaiting second char.
var mid_swap := ""

var use_layout = LayoutType.US
onready var row_container = $rows


func _ready():
	generate_keyboard()
	var res = connect("key_pressed", self, "on_key_pressed")
	if res != OK:
		push_error("Failed to connect keypress")


func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed:
		var keystr = OS.get_scancode_string(event.get_scancode_with_modifiers())
		emit_signal("key_pressed", keystr.to_lower())


## Generate or regenerate the overall keyboard.
func generate_keyboard() -> void:
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
func add_key_to_row(parent_row:HBoxContainer, key:String) -> void:
	var new_key = KeyButton.instance()
	new_key.text = key
	parent_row.add_child(new_key)
	new_key.connect("pressed_with_value", self, "on_key_pressed")


## When a new character is pressed by shortcut key or virtual key press.
func on_key_pressed(character:String) -> void:
	if not is_active:
		return
	if not character.to_lower() in LoadScramble.ONLY_SCRAMBLE_CHARS:
		# Skip other characters like esc etc.
		return
	if mid_swap == "":
		mid_swap = character
		highlight_key(character, true)
	else:
		game_scene.state.swap_chars(character, mid_swap)
		highlight_key(mid_swap, false)
		mid_swap = ""
	
	var focus_button := get_key(character)
	if focus_button:
		focus_button.grab_focus()
	# Raise signal to parent?


func get_key(key:String) -> Button:
	var node_ref:Button
	for row in row_container.get_children():
		for button in row.get_children():
			if button is Button and button.text.to_lower() == key:
				node_ref = button
				break
	if node_ref == null:
		push_error("Could not find the button")
		return null
	return node_ref
	

func highlight_key(key:String, enable:bool) -> void:
	var node_ref := get_key(key)
	if not node_ref:
		return
	# Do more styling
	if enable:
		node_ref.set_position(node_ref.rect_position + Vector2(0, 3))
	else:
		node_ref.set_position(node_ref.rect_position - Vector2(0, 3))
