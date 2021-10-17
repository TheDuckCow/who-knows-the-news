## Object structure for maintaining the state of a Scramble.
extends Reference

var solution_phrase: String
var starting_phrase: String
var current_phrase: String

var article_page_url: String
var article_image_url: String
var article_credit_title: String

var turns_taken: int = 0


func _init(solution, start):
	solution_phrase = solution
	starting_phrase = start
	current_phrase = start
	turns_taken = 0


func reset():
	turns_taken += 1
	current_phrase = starting_phrase
