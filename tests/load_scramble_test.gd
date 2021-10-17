## Unit test for using loading scrambles
extends WAT.Test

const LoadScramble = preload("res://logic/load_scramble.gd")

func title() -> String:
	return "Given LoadScramble"


func test_apply_scramble_valid_transform() -> void:
	describe("When applying scramble to valid examples")
	var start = "Go"
	var transform = {"g":"a", "o":"z"}
	var expected = "Az"
	var res = LoadScramble.apply_scramble(start, transform)
	asserts.is_equal(res, expected, "transform of Go matches expectation")
	
	start = "test"
	transform = {"t":"z", "e":"f", "s":"q"}
	expected = "zfqz"
	res = LoadScramble.apply_scramble(start, transform)
	asserts.is_equal(res, expected, "transform of test matches expectation")
	
	start = "Some, example!"
	transform = {"s":"o", "o":"m", "m":"e", "e":"x", "x":"a", "a":"p", "p":"l", "l":"s"}
	expected = "Omex, xapelsx!"
	res = LoadScramble.apply_scramble(start, transform)
	asserts.is_equal(res, expected, "transform of phrase matches expectation")


func test_apply_scramble_bad_transform() -> void:
	describe("When applying scramble to a invalid example")
	var start = "Go"
	
	var transform = {"g":"a", "o":"a"}
	var res = LoadScramble.apply_scramble(start, transform)
	asserts.is_null(res, "null for repeat of output mapping")
	
	transform = {"g":"a"}
	res = LoadScramble.apply_scramble(start, transform)
	asserts.is_null(res, "null for missing letter mapping")
	
	transform = {"g":"a", "o":"bc"}
	res = LoadScramble.apply_scramble(start, transform)
	asserts.is_null(res, "null for wrong length of source transform value")


func test_generate_transform() -> void:
	describe("When generating a new transform")
	var transform = LoadScramble.generate_transform()
	asserts.is_not_null(transform, "transform is not null")
	
	var res = LoadScramble.apply_scramble("sample", transform)
	asserts.is_not_null(res, "transform was valid")
