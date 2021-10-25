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
	
	Cache.udpate_session_solve(self)


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


func solve_one_char(give_penalty:bool):
	if is_solved:
		return
	# Find all indeces where the correct character is not placed
	var avail_solution = []
	var avail_current = []
	for i in range(len(current_phrase)):
		if current_phrase[i].to_lower() != solution_phrase[i].to_lower():
			if not solution_phrase[i].to_lower() in avail_solution:
				avail_solution.append(solution_phrase[i].to_lower())
				avail_current.append(current_phrase[i].to_lower())
	
	# Pick a random index to swap
	if not avail_solution:
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
	var ind = randi() % avail_solution.size()
	swap_chars(avail_solution[ind], avail_current[ind])
	print_debug("Hint swapped %s & %s" %  [avail_solution[ind], avail_current[ind]])


func give_up():
	current_phrase = solution_phrase
	end_msec = OS.get_ticks_msec()
	is_solved = true
	gave_up = true
	Cache.udpate_session_solve(self)
	#print("Gave up")
