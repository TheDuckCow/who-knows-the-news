## Object structure for maintaining the state of a Scramble.
class_name ScrambleState
extends Reference

signal state_updated_phrase
signal puzzle_solved

const HINT_PENALTY := 10

var solution_phrase: String
var starting_phrase: String
var current_phrase: String

var start_msec: int
var end_msec: int
var is_solved := false
var gave_up := false

# Acts as a primary key for caching.
var article_page_url: String
var publisher_url: String

var turns_taken:int = 0
var hints_given:int = 0
var last_swap_char:Array


func _init(solution, start, url):
	solution_phrase = solution
	starting_phrase = start
	current_phrase = start
	turns_taken = 0
	start_msec = OS.get_ticks_msec()
	check_solved()
	article_page_url = url
	publisher_url = domain_from_url(url)
	
	Cache.udpate_session_solve(self)


## Remove pages from (sub)domain, no trailing /
static func domain_from_url(url:String) -> String:
	if not url:
		return ""
	var break_i
	var last_was_slash = false
	for i in range(len(url)):
		break_i = i
		if url[i] == "/" and not last_was_slash:
			last_was_slash = true
			if len(url) == i+1:
				break # Confirmed that it's a string ending in /
			elif url[i+1] != "/":
				break # Confirming not the // in http://...
		else:
			last_was_slash = false
	if not last_was_slash:
		break_i += 1 # For end of string
	return url.left(break_i)


func reset():
	turns_taken += 1
	current_phrase = starting_phrase
	last_swap_char = []
	check_solved()


## Swap two characters, preserving cases in the original string.
func swap_chars(a:String, b:String):
	var updated := false
	if len(a) != 1 or len(b) != 1:
		push_error("Wrong length for character swaps")
	if a.to_lower() == b.to_lower():
		return # Cancel mid swap
	last_swap_char = [a, b]
	for ind in range(len(current_phrase)):
		if current_phrase[ind].to_lower() == a.to_lower():
			if current_phrase[ind] == a.to_lower():
				current_phrase[ind] = b
			else:
				current_phrase[ind] = b.to_upper()
			updated = true
		elif current_phrase[ind].to_lower() == b.to_lower():
			if current_phrase[ind] == b.to_lower():
				current_phrase[ind] = a.to_lower()
			else:
				current_phrase[ind] = a.to_upper()
			updated = true
	turns_taken += 1
	check_solved()
	Cache.udpate_session_solve(self)
	if updated:
		emit_signal("state_updated_phrase")


func check_solved():
	if solution_phrase != current_phrase:
		return
	end_msec = OS.get_ticks_msec()
	is_solved = true
	print("Puzzle solved!")
	emit_signal("puzzle_solved")


func undo_last_swap():
	if last_swap_char:
		swap_chars(last_swap_char[0], last_swap_char[1])
		check_solved() # More a sanity safeguard than anything.


func still_scrambled_letters() -> Dictionary:
	if is_solved:
		return {}
	# Find all indeces where the correct character is not placed
	var avail = {}
	for i in range(len(current_phrase)):
		if current_phrase[i].to_lower() != solution_phrase[i].to_lower():
			if not solution_phrase[i].to_lower() in avail:
				avail[solution_phrase[i].to_lower()] = current_phrase[i].to_lower()
	return avail


func allowed_keys() -> Array:
	return still_scrambled_letters().keys()


func solve_one_char(give_penalty:bool) -> void:
	if is_solved:
		return
	# Find all indeces where the correct character is not placed
	var avail = still_scrambled_letters()
	
	# Pick a random index to swap
	if not avail:
		push_error("Failed to find any characters to swap")
		check_solved()
		return

	# Apply penalty, and trigger ending condition check.
	if give_penalty:
		turns_taken += HINT_PENALTY-1 # One applied from swap_chars already.
		hints_given += 1
	else:
		turns_taken -= 1

	# Pick which character we want to put into the right place
	var keys = avail.keys()
	var ind = randi() % keys.size()
	swap_chars(keys[ind], avail[keys[ind]])
	print_debug("Hint swapped %s & %s" %  [keys[ind], avail[keys[ind]]])


func give_up():
	current_phrase = solution_phrase
	end_msec = OS.get_ticks_msec()
	is_solved = true
	gave_up = true
	Cache.udpate_session_solve(self)
	#print("Gave up")
