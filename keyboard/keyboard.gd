## Defines the overall size of the interactiv keyboard.
extends Control

enum LayoutType {
	US
}

# Fired when a staged swap has begun
# warning-ignore:unused_signal
signal key_pressed(character)
# Allows for the interactive headline to ensure it updates after the mid_swap
# variable has been updated.
signal key_press_processed()

const SmallFont = preload("res://fonts/cotham-sans/cotham_16.tres")
const MediumFont = preload("res://fonts/cotham-sans/cotham_20.tres")
const LoadScramble = preload("res://logic/load_scramble.gd")
const MOD_BLUE = Color(0.7, 0.8, 1.0)
const MOD_RED = Color(1.0, 0.8, 0.8)
const MOD_NONE = Color(1.0, 1.0, 1.0)

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

onready var KeyButton = preload("res://keyboard/key_button.tscn")
onready var row_container := get_node("rows")
onready var key_audio := get_node("key_audio")

var game_scene := Node

# Way to disable the keyboard if needed, e.g. on game win.
var is_active := true
var allowed_keys = []
var use_small_font := false

# To indicate if in the middle of swapping 2 characters, awaiting second char.
var mid_swap := ""

var use_layout = LayoutType.US


func _ready():
	# generate_keyboard() # Called by parent when ready.

	# When any source triggers a key press, even if not from this node itself
	# (e.g. by headline), process them the same via this signal.
	var res = connect("key_pressed", self, "on_key_pressed")
	if res != OK:
		push_error("Failed to connect keypress")


func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed:
		var keystr = OS.get_scancode_string(event.get_scancode_with_modifiers())
		if not keystr.to_lower() in LoadScramble.ONLY_SCRAMBLE_CHARS:
			return

		# Not using arrow keys, release focus from headline button(s).
		release_focus()
		emit_signal("key_pressed", keystr.to_lower())


func get_target_button_size() -> float:
	var pnode = get_node("../")
	var parent_width = pnode.rect_size.x
	var max_row_width = 0
	for row in LAYOUT[use_layout]:
		if len(row) > max_row_width:
			max_row_width = len(row)
	var button_size = 0
	if max_row_width > 0:
		button_size = (parent_width * 0.85) / max_row_width
	else:
		push_warning("Couldn't get best keyboard size")
	return button_size


## Generate or regenerate the overall keyboard.
func generate_keyboard() -> void:
	for row in row_container.get_children():
		# Disconnect needed?
		row.queue_free()
	
	var button_size = get_target_button_size()
	
	for row in LAYOUT[use_layout]:
		var new_row = HBoxContainer.new()
		row_container.add_child(new_row)
		var start_spacer := Control.new()
		start_spacer.size_flags_horizontal = SIZE_EXPAND
		var end_spacer := Control.new()
		end_spacer.size_flags_horizontal = SIZE_EXPAND
		new_row.add_child(start_spacer)
		for key in row:
			add_key_to_row(new_row, key, button_size)
		new_row.add_child(end_spacer)
	if mid_swap:
		highlight_key(mid_swap, true)


## Populate a single row of keys, connecting signals as needed.
func add_key_to_row(parent_row:HBoxContainer, key:String, size:float) -> void:
	var new_key = KeyButton.instance()
	new_key.size = size
	new_key.text = key
	if use_small_font:
		#new_key.add_font_override(SmallFont)
		#print_debug("CURRENT SIZE: ", new_key.get_font("font"))
		#var dynamicfont = new_key.get_font("font")
		new_key.set("custom_fonts/font", SmallFont)
	else:
		new_key.set("custom_fonts/font", MediumFont)

	parent_row.add_child(new_key)
	new_key.connect("pressed_with_value", self, "on_key_button_press")


func update_allowed_keys(_allowed_keys: Array):
	#allowed_keys = [] # A cache used for future key presses and display.
	allowed_keys = _allowed_keys
	#var tmp = solution.to_lower()
	#for ch in LoadScramble.ONLY_SCRAMBLE_CHARS:
	#	if ch in tmp:
	#		allowed_keys.append(ch)
	
	var size = get_target_button_size() # Update based on layout space.
	
	var valid_key = null
	for row in row_container.get_children():
		if not row.visible:
			continue # Potentially pending deletion.
		for button in row.get_children():
			if not button is Button:
				continue
			var key:Button = button
			key.size = size
			if is_disabled_char(key.text):
				key.disabled = true
				key.focus_mode = Button.FOCUS_NONE
			else:
				if not valid_key:
					valid_key = key
				key.disabled = false
				# Update: Not allowing focus on buttons, in favor of headline.
				key.focus_mode = Button.FOCUS_NONE # FOCUS_ALL

	# Detect if nothing is focussed, then pick a first valid key if not
	# Removed this in favor of focussing on headline if needed.
	#if valid_key and not get_focus_owner():
		#print_debug("No focus owner, assigning a valid key: ", valid_key.text)
		#valid_key.grab_focus()


func is_disabled_char(key:String):
	var keyl = key.to_lower()
	if keyl in LoadScramble.ONLY_SCRAMBLE_CHARS and not keyl in allowed_keys:
		return true
	return false
	

func on_key_button_press(character) -> void:
	emit_signal("key_pressed", character)


## When a new character is pressed by shortcut key or virtual key press.
func on_key_pressed(character:String) -> void:
	if not is_active:
		return
	if is_disabled_char(character):
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
	
	# Update the title.
	var focus_button := get_key(character)
	if focus_button and not focus_button.disabled:
		if focus_button.focus_mode != Button.FOCUS_NONE:
			focus_button.grab_focus()
	make_key_sound()
	emit_signal("key_press_processed")
	print_debug("Finished keybaord on_key_pressed (including swap update)")


func make_key_sound():
	if Cache.sound_on:
		key_audio.pitch_scale = 1 + randf() * 0.3
		key_audio.play(0)


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
	if enable:
		node_ref.modulate = MOD_BLUE
		node_ref.set_position(node_ref.rect_position + Vector2(0, 3))
	else:
		node_ref.modulate = MOD_NONE
		node_ref.set_position(node_ref.rect_position - Vector2(0, 3))
