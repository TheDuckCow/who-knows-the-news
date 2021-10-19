## Object structure for maintaining the state of a Scramble.
extends Reference

signal state_updated_phrase
signal puzzle_solved

var solution_phrase: String
var starting_phrase: String
var current_phrase: String

var start_msec: int
var end_msec: int
var is_solved := false

var article_page_url: String
var article_image_url: String
var article_credit_title: String

var turns_taken: int = 0


func _init(solution, start):
	solution_phrase = solution
	starting_phrase = start
	current_phrase = start
	turns_taken = 0
	start_msec = OS.get_ticks_msec()
	check_solved()


func reset():
	turns_taken += 1
	current_phrase = starting_phrase
	check_solved()


## Swap two characters, preserving cases in the original string.
func swap_chars(a:String, b:String):
	var updated := false
	if len(a) != 1 or len(b) != 1:
		push_error("Wrong length for character swaps")
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
	if updated:
		emit_signal("state_updated_phrase")


func check_solved():
	if solution_phrase != current_phrase:
		return
	end_msec = OS.get_ticks_msec()
	is_solved = true
	print("Puzzle solved!")
	emit_signal("puzzle_solved")