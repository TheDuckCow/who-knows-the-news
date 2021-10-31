## Perform creation of word textwrapping.
##
## Uses a hack to extract wordwrapping positions used to then group word-grouped
## letter by letter buttons generated.
extends RichTextLabel

signal word_wrapp_done(lines)
signal key_pressed(key)

const LoadScramble = preload("res://logic/load_scramble.gd")
const HeadlineButton := preload("res://views/headline_char_button.tscn")
const ScrambleState := preload("res://logic/scramble_state.gd")

onready var text_row := get_node("text_row")

export var test_value := ""
export var test_swap := ""

var state
var mid_swap := ""

var initial_generation_done := false
var is_mid_update := false

var _rerun_queued_state := false


func _ready():
	if test_value:
		state = ScrambleState.new(test_value, test_value, "url")
		set_headline(state, test_swap)
	
	var res = connect("word_wrapp_done", self, "_on_word_wrap_done")
	if res != OK:
		push_error("Failed to connect word_wrapp_done")


func _on_key_press(key):
	emit_signal("key_pressed", key)


func _update_underline(btn:Button) -> void:
	if mid_swap and mid_swap.to_lower() == btn.text.to_lower():
		btn.underline.visible = true
	else:
		btn.underline.visible = false


func set_headline(_state, _mid_swap:String) -> void:
	if not initial_generation_done:
		print_debug("Not ready for initial set of headline")
		state = _state
		mid_swap = _mid_swap
	print_debug("Started to set headline")
	if is_mid_update:
		push_warning("Tried to set headline before first one was ready")
		_rerun_queued_state = true
	elif _rerun_queued_state:
		print_debug("Running headline update post-queued")
		_rerun_queued_state = false
	is_mid_update = true # To avoid crashings trying to iterate over mid udpates.
	state = _state
	mid_swap = _mid_swap
	visible = true
	if not state: # E.g. if it failed to load.
		bbcode_text = ""
		return
	self_modulate.a = 0.0 # Present for spacing, but not visible.
	
	# Beacuse of the use of yields over multiple frames to test word wrapping,
	# must use signal callback.
	generate_word_lines(state.current_phrase)


# Old method, which directly colorized an auto-wrapping rich text using bbcode.
#func old_generator(_state, _mid_swap):
#	mid_swap = _mid_swap
#	self_modulate.a = 1
#	var tmp_phrase = []
#	for i in range(len(state.current_phrase)):
#		if _state.current_phrase[i] == _state.solution_phrase[i]:
#			if _state.current_phrase[i] == mid_swap and false:
#				# Warn that it's already a valid character, don't swap!
#				tmp_phrase.append("[color=red]%s[/color]" % _state.current_phrase[i])
#			else:
#				# Black for already correct charater;
#				# have no color here so that word wrapping works on solution.
#				tmp_phrase.append("%s" % _state.current_phrase[i])
#		else:
#			if _state.current_phrase[i] == mid_swap and false:
#				# Highlight the character being swapped.
#				tmp_phrase.append("[color=blue]%s[/color]" % _state.current_phrase[i])
#			else:
#				# Lighter color for not yet confirmed
#				tmp_phrase.append("[color=gray]%s[/color]" % _state.current_phrase[i])
#
#	bbcode_text = "[center]%s[/center]" % PoolStringArray(tmp_phrase).join("")
#	#testing_row.visible = false


## Test line width one word at a time to define where wrapping should occur.
## Test is done by seeing if height of box extends.
## Returns: array of lines. each line is itself an array of individual words.
func generate_word_lines(solution:String) -> void:
	var words = solution.split(" ")
	var lines = [[]]

	# Clear current values
	self.bbcode_text = ""
	for child in text_row.get_children():
		child.visible = false

	for i in range(words.size()):
		var ind = lines.size() - 1
		lines[ind].append(words[i])
		var tst_str = PoolStringArray(lines[ind]).join(" ")
		self.bbcode_text = tst_str
		# Need UI layouts to update to catch word wrapping.
		yield(get_tree(), "idle_frame")
		#print("Line count: ", self.get_line_count(), ", ", self.get_visible_line_count())
		if get_visible_line_count() > 1:
			lines[ind].remove(lines[ind].size()-1)
			lines.append([words[i]])

	# Finally, update the headline once more with the whole phrase so that it
	# updates to the correct size, but then make it not (self) visible.
	var final_str = []
	for row in lines:
		final_str.append(PoolStringArray(row).join(" "))
	self.bbcode_text = PoolStringArray(final_str).join("\n")
	yield(get_tree(), "idle_frame")
	emit_signal("word_wrapp_done", lines)


func _on_word_wrap_done(lines:Array):
	#print_debug("Generate headline buttons on_word_wrap_done")
	for child in text_row.get_children():
		child.visible = false
		child.queue_free()
	
	for line in lines:
		var hbox := HBoxContainer.new()
		hbox.alignment = hbox.ALIGN_CENTER
		hbox.set("custom_constants/separation", 0)
		text_row.add_child(hbox)
		var is_first_line = true
		for word in line:
			if not is_first_line:
				var spacer = Control.new()
				spacer.rect_min_size.x = 10
				hbox.add_child(spacer)
			else:
				is_first_line = false
			for ltr in word:
				var btn:Button = HeadlineButton.instance()
				var res = btn.connect("key_pressed", self, "_on_key_press")
				if res != OK:
					push_error("Could not conenct key press")
				btn.text = ltr
				if not ltr.to_lower() in LoadScramble.ONLY_SCRAMBLE_CHARS:
					btn.disabled = true
				hbox.add_child(btn)
				_update_underline(btn)

	# Now apply current phrase.
	is_mid_update = false
	update_headline()
	initial_generation_done = true


func update_headline():
	if is_mid_update:
		push_warning("Tried to update headline in middle of update")
	else:
		print("Updating interactive headline")
	var ind = 0
	for row in text_row.get_children():
		if not row.visible:
			continue # Queued deletion from prior step.
		for btn in row.get_children():
			if ind >= len(state.current_phrase):
				push_error("Iteration index %s exceeded phrase length: %s" % [
					ind, state.current_phrase])
				break
			if not btn is Button:
				ind += 1
				continue
			elif not state.current_phrase[ind].to_lower() in LoadScramble.ONLY_SCRAMBLE_CHARS:
				pass
			elif state.solution_phrase[ind] == state.current_phrase[ind]:
				btn.disabled = true if not test_value else false
			else:
				btn.disabled = false

			_update_underline(btn)
			btn.text = state.current_phrase[ind]
			ind += 1
		ind += 1 # For end of line, would be a sapce.
	self_modulate.a = 0.0
